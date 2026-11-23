-- Tabs por panel (como los grupos de editor de VS Code).
-- Cada ventana de edición tiene su propia fila de tabs (winbar) con los archivos
-- que se abrieron en ella. Reemplaza a bufferline.

local M = {}
local api = vim.api

---@type table<integer, integer[]> win -> lista de buffers (en orden de la barra)
local tabs = {}
local fresh = {} -- ventanas recién creadas por un split

local function is_file_buf(buf)
  return api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and vim.bo[buf].buflisted
    and api.nvim_buf_get_name(buf) ~= ""
end

local function is_editor_win(win)
  return api.nvim_win_is_valid(win) and api.nvim_win_get_config(win).relative == ""
    and vim.bo[api.nvim_win_get_buf(win)].filetype ~= "NvimTree"
end

-- Lista de la ventana, sin buffers borrados
function M.list(win)
  win = win or api.nvim_get_current_win()
  local l = vim.tbl_filter(is_file_buf, tabs[win] or {})
  tabs[win] = l
  return l
end

function M.set(win, bufs) tabs[win] = vim.deepcopy(bufs) end

local function add(win, buf)
  if not is_file_buf(buf) then return end
  local l = M.list(win)
  if fresh[win] then
    -- un split hereda el archivo del panel original; si enseguida se abre otro, se descarta
    if #l == 1 and l[1] ~= buf then l = {} end
  end
  if not vim.tbl_contains(l, buf) then
    -- se inserta a la derecha de la tab activa, como VS Code
    local cur = vim.w[win].wintabs_prev
    local idx = cur and vim.fn.index(l, cur) or -1
    table.insert(l, idx >= 0 and idx + 2 or #l + 1, buf)
  end
  tabs[win] = l
  vim.w[win].wintabs_prev = buf
end

-- ¿Algún panel (distinto de `except`) tiene este buffer como tab?
local function in_other_win(buf, except)
  for win, l in pairs(tabs) do
    if win ~= except and api.nvim_win_is_valid(win) and vim.tbl_contains(l, buf) then return true end
  end
  return false
end

local function delete_if_orphan(buf, except)
  if api.nvim_buf_is_valid(buf) and not vim.bo[buf].modified and not in_other_win(buf, except)
    and #vim.fn.win_findbuf(buf) == 0 then
    pcall(api.nvim_buf_delete, buf, {})
  end
end

----------------------------------------------------------------------------- render

local function hl(name, text) return "%#" .. name .. "#" .. text end

local ok_icons, devicons = pcall(require, "nvim-web-devicons")

function M.render()
  local win = vim.g.statusline_winid or api.nvim_get_current_win()
  local l = M.list(win)
  local cur = api.nvim_win_get_buf(win)
  local focused = win == api.nvim_get_current_win()
  -- nombres repetidos → se agrega la carpeta
  local count = {}
  for _, b in ipairs(l) do
    local t = vim.fn.fnamemodify(api.nvim_buf_get_name(b), ":t")
    count[t] = (count[t] or 0) + 1
  end
  local parts = {}
  for _, b in ipairs(l) do
    local path = api.nvim_buf_get_name(b)
    local name = vim.fn.fnamemodify(path, ":t")
    if count[name] > 1 then name = vim.fn.fnamemodify(path, ":h:t") .. "/" .. name end
    local sel = b == cur
    local group = sel and (focused and "WinTabSel" or "WinTabSelNC") or "WinTab"
    local icon = ""
    if vim.g.have_nerd_font and ok_icons then
      local ic = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
      icon = (ic or "") .. " "
    end
    local errs = vim.diagnostic.count(b)[vim.diagnostic.severity.ERROR] or 0
    local warns = vim.diagnostic.count(b)[vim.diagnostic.severity.WARN] or 0
    local diag = ""
    -- en la píldora activa (azul) el rojo/amarillo no se lee: usa el color del texto
    local function dg(kind) return sel and (focused and group or "WinTab" .. kind .. "Sel") or "WinTab" .. kind end
    if errs > 0 then diag = hl(dg("Err"), " ✖" .. errs)
    elseif warns > 0 then diag = hl(dg("Warn"), " ▲" .. warns) end
    local mod = vim.bo[b].modified and " ●" or ""
    -- pestaña tipo píldora: extremos redondeados (Nerd Font) o planos
    local l_cap, r_cap = "", ""
    if vim.g.have_nerd_font then l_cap, r_cap = hl(group .. "Cap", ""), hl(group .. "Cap", "") end
    table.insert(parts, ("%%%d@v:lua.WinTabs_click@"):format(b)
      .. l_cap .. hl(group, " " .. icon .. name .. mod) .. diag .. hl(group, " ") .. r_cap
      .. "%X" .. hl("WinTabFill", " "))
  end
  return "%<" .. table.concat(parts) .. hl("WinTabFill", "")
end

-- clic: izquierdo = ir a la tab, medio = cerrarla
function _G.WinTabs_click(buf, _, button)
  local win = vim.fn.getmousepos().winid
  if not api.nvim_win_is_valid(win) then return end
  api.nvim_set_current_win(win)
  if button == "m" then
    if api.nvim_win_get_buf(win) ~= buf then api.nvim_win_set_buf(win, buf) end
    M.close()
  else
    api.nvim_win_set_buf(win, buf)
  end
end

----------------------------------------------------------------------------- acciones

function M.cycle(step)
  local l, cur = M.list(), api.nvim_get_current_buf()
  if #l < 2 then return end
  local i = vim.fn.index(l, cur) + 1
  if i == 0 then i = 1 end
  api.nvim_set_current_buf(l[(i - 1 + step) % #l + 1])
end

function M.go(n)
  local l = M.list()
  if l[n] then api.nvim_set_current_buf(l[n]) end
end

function M.move(step)
  local win, cur = api.nvim_get_current_win(), api.nvim_get_current_buf()
  local l = M.list(win)
  local i = vim.fn.index(l, cur) + 1
  local j = i + step
  if i == 0 or j < 1 or j > #l then return end
  l[i], l[j] = l[j], l[i]
  vim.cmd.redrawstatus()
end

-- Cierra la tab actual del panel. Si era la última y hay otros paneles, cierra el panel.
function M.close()
  local win, buf = api.nvim_get_current_win(), api.nvim_get_current_buf()
  -- paneles especiales (logs de Flutter, outline, ayuda…): cerrar el panel sin borrar su buffer
  if vim.bo[buf].buftype ~= "" then
    if #vim.tbl_filter(is_editor_win, api.nvim_tabpage_list_wins(0)) > 1 then
      return api.nvim_win_close(win, false)
    end
    return vim.cmd.enew()
  end
  if vim.bo[buf].modified then
    return vim.notify("Hay cambios sin guardar (<leader>w)", vim.log.levels.WARN)
  end
  local l = M.list(win)
  local i = vim.fn.index(l, buf) + 1
  if i > 0 then table.remove(l, i) end
  local editors = vim.tbl_filter(is_editor_win, api.nvim_tabpage_list_wins(0))
  if #l > 0 then
    api.nvim_win_set_buf(win, l[math.max(1, i - 1)] or l[1])
  elseif #editors > 1 then
    tabs[win] = nil
    api.nvim_win_close(win, false)
  else
    vim.cmd.enew()
  end
  delete_if_orphan(buf)
end

function M.close_others()
  local win, buf = api.nvim_get_current_win(), api.nvim_get_current_buf()
  local others = vim.tbl_filter(function(b) return b ~= buf end, M.list(win))
  tabs[win] = { buf }
  for _, b in ipairs(others) do delete_if_orphan(b) end
  vim.cmd.redrawstatus()
end

----------------------------------------------------------------------------- setup

local function set_highlights()
  local ok, theme = pcall(require, "gruvbox-flutter")
  local p = ok and theme.palette or {
    bg0 = "#282828", bg1 = "#32302f", bg3 = "#3c3836", bg4 = "#45403d", fg = "#ebdbb2", grey1 = "#928374",
    blue = "#7daea3", red = "#ea6962", yellow = "#d8a657",
  }
  local set = function(n, o) api.nvim_set_hl(0, n, o) end
  set("WinTabFill", { bg = p.bg1 })
  set("WinTab", { fg = p.grey1, bg = p.bg3 })
  set("WinTabSel", { fg = p.bg0, bg = p.blue, bold = true })
  set("WinTabSelNC", { fg = p.fg, bg = p.bg4 })
  -- extremos redondeados: color de la píldora sobre el fondo de la barra
  set("WinTabCap", { fg = p.bg3, bg = p.bg1 })
  set("WinTabSelCap", { fg = p.blue, bg = p.bg1 })
  set("WinTabSelNCCap", { fg = p.bg4, bg = p.bg1 })
  set("WinTabErr", { fg = p.red, bg = p.bg3 })
  set("WinTabErrSel", { fg = p.red, bg = p.bg4 })
  set("WinTabWarn", { fg = p.yellow, bg = p.bg3 })
  set("WinTabWarnSel", { fg = p.yellow, bg = p.bg4 })
  set("WinBar", { bg = p.bg1 })
  set("WinBarNC", { bg = p.bg1 })
end

local WINBAR = "%{%v:lua.require'wintabs'.render()%}"

local function update_winbar(win)
  if not api.nvim_win_is_valid(win) or api.nvim_win_get_config(win).relative ~= "" then return end
  local buf = api.nvim_win_get_buf(win)
  local want = (is_file_buf(buf) or (vim.bo[buf].buftype == "" and #M.list(win) > 0)) and WINBAR or ""
  if vim.wo[win].winbar ~= want then vim.wo[win][0].winbar = want end
end

function M.setup()
  set_highlights()
  local g = api.nvim_create_augroup("wintabs", { clear = true })
  api.nvim_create_autocmd("ColorScheme", { group = g, callback = set_highlights })
  api.nvim_create_autocmd("WinNew", {
    group = g,
    callback = function()
      local win = api.nvim_get_current_win()
      fresh[win] = true
      vim.schedule(function() fresh[win] = nil end)
    end,
  })
  api.nvim_create_autocmd("BufWinEnter", {
    group = g,
    callback = function(ev)
      local win = api.nvim_get_current_win()
      if api.nvim_win_get_buf(win) == ev.buf then add(win, ev.buf) end
      update_winbar(win)
    end,
  })
  api.nvim_create_autocmd({ "FileType", "TermOpen" }, {
    group = g, callback = function() update_winbar(api.nvim_get_current_win()) end,
  })
  api.nvim_create_autocmd("WinClosed", {
    group = g,
    callback = function(ev)
      local win = tonumber(ev.match)
      if win then tabs[win], fresh[win] = nil, nil end
    end,
  })
  api.nvim_create_autocmd({ "BufModifiedSet", "DiagnosticChanged" }, {
    group = g, callback = function() vim.cmd("silent! redrawstatus!") end,
  })
  -- ventanas que ya existen
  for _, win in ipairs(api.nvim_list_wins()) do
    if is_editor_win(win) then add(win, api.nvim_win_get_buf(win)); update_winbar(win) end
  end
end

return M
