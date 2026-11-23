-- Barra lateral: nvim-tree arriba y Flutter Outline (árbol de widgets) abajo, en la
-- misma columna, como un solo componente.
--  * <leader>n  muestra/oculta todo (con la animación de lua/anim.lua).
--  * El Outline solo aparece si el archivo actual es Dart y el LSP ya mandó su árbol;
--    al pasar a un archivo que no es Dart se quita, y vuelve al regresar.
--  * <leader>N  muestra/oculta solo la mitad del Outline.
local M = {}
local api = vim.api
local anim = require("anim")

local OUTLINE_FT = "flutterToolsOutline"
local outline_wanted = true -- <leader>N lo apaga/enciende

local function tree_win() return anim.find_panel("NvimTree") end

----------------------------------------------------------------------- títulos

local nf = vim.g.have_nerd_font
local TITLES = {
  NvimTree = { name = "EXPLORER", icon = "\u{f0645}", hl = "SidebarExplorer" },      -- 󰙅
  [OUTLINE_FT] = { name = "WIDGET TREE", icon = "\u{f072b}", hl = "SidebarWidgets" }, -- 󰜫
}

local function set_highlights()
  local ok, theme = pcall(require, "gruvbox-flutter")
  local p = ok and theme.palette or { bg0 = "#282828", bg4 = "#45403d", fg = "#ebdbb2",
    grey1 = "#928374", blue = "#7daea3", aqua = "#89b482" }
  local set = function(n, o) api.nvim_set_hl(0, n, o) end
  set("SidebarTitle", { fg = p.fg, bg = p.bg4, bold = true })
  set("SidebarTitleDim", { fg = p.grey1, bg = p.bg4, italic = true })
  set("SidebarExplorer", { fg = p.blue, bg = p.bg4 })
  set("SidebarWidgets", { fg = p.aqua, bg = p.bg4 })
end

-- Texto de la barra de título (se evalúa al dibujar: el archivo del outline cambia)
function M.title(ft)
  local t = TITLES[ft]
  if not t then return "" end
  local icon = nf and ("%#" .. t.hl .. "# " .. t.icon) or ""
  local right = ""
  if ft == OUTLINE_FT then
    local win = vim.g.statusline_winid or api.nvim_get_current_win()
    local uri = vim.b[api.nvim_win_get_buf(win)].outline_uri
    if uri then right = "%#SidebarTitleDim#" .. vim.fn.fnamemodify(vim.uri_to_fname(uri), ":t") .. " " end
  end
  return "%<" .. icon .. "%#SidebarTitle# " .. t.name .. " %=" .. right
end

local function apply_title(win)
  if not api.nvim_win_is_valid(win) then return end
  local ft = vim.bo[api.nvim_win_get_buf(win)].filetype
  if not TITLES[ft] then return end
  vim.w[win].sidebar_title = true
  local bar = ("%%{%%v:lua.require'sidebar'.title('%s')%%}"):format(ft)
  if vim.wo[win].winbar ~= bar then vim.wo[win][0].winbar = bar end
end

local function apply_titles()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do apply_title(win) end
end

-------------------------------------------------------------------------------
local function outline_win() return anim.find_panel(OUTLINE_FT) end

local function is_editor(win)
  if not api.nvim_win_is_valid(win) or api.nvim_win_get_config(win).relative ~= "" then return false end
  local buf = api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "NvimTree"
end

-- Ventana de código de referencia: la actual o la anterior (si el foco está en el árbol)
local function editor_win()
  local cur = api.nvim_get_current_win()
  if is_editor(cur) then return cur end
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  if prev ~= 0 and is_editor(prev) then return prev end
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if is_editor(win) then return win end
  end
end

-- ¿Hay outline para el archivo de esta ventana?
local function outline_available(win)
  if not win then return false end
  local buf = api.nvim_win_get_buf(win)
  if vim.bo[buf].filetype ~= "dart" then return false end
  local ok, outline = pcall(require, "flutter-tools.outline")
  local data = ok and outline.outlines[vim.uri_from_bufnr(buf)]
  return data ~= nil and not vim.tbl_isempty(data)
end

-- Mitad y mitad dentro de la columna
local function equalize()
  local t, o = tree_win(), outline_win()
  if not (t and o) then return end
  local total = api.nvim_win_get_height(t) + api.nvim_win_get_height(o)
  api.nvim_win_set_height(o, math.floor(total / 2))
end

function M.close_outline()
  local o = outline_win()
  if o then pcall(api.nvim_win_close, o, true) end
end

-- Pone el Outline debajo del árbol (si hay árbol, outline disponible y no está ya)
function M.dock_outline()
  local t = tree_win()
  if not t or not outline_wanted or outline_win() then return end
  local ed = editor_win()
  if not outline_available(ed) then return end
  local prev = api.nvim_get_current_win()
  local width = api.nvim_win_get_width(t)
  -- flutter-tools abre el outline del buffer de la ventana actual, junto a ella
  api.nvim_set_current_win(ed)
  require("flutter-tools.outline").open({ go_back = true })
  local o = outline_win()
  if o then
    -- se mueve a la columna del árbol, debajo de él
    vim.fn.win_splitmove(o, t, { vertical = false, rightbelow = true })
    vim.wo[o].winfixwidth = false
    api.nvim_win_set_width(t, width) -- al abrirse a la derecha nvim repartió el ancho
    apply_title(o)
    equalize()
  end
  if api.nvim_win_is_valid(prev) then api.nvim_set_current_win(prev) end
end

-- Al cambiar de archivo: outline sí/no según el archivo
local function sync()
  if not tree_win() then return end
  local ed = editor_win()
  if outline_wanted and outline_available(ed) then
    M.dock_outline()
  elseif ed and api.nvim_get_current_win() == ed then
    M.close_outline() -- archivo sin outline (no Dart): solo árbol
  end
end

-- <leader>n
function M.toggle()
  local t = tree_win()
  if t then
    anim.panel_close(t, function()
      M.close_outline()
      vim.cmd("NvimTreeClose")
    end)
  else
    vim.cmd("NvimTreeOpen")
    M.dock_outline()
  end
end

-- <leader>N
function M.toggle_outline()
  if outline_win() then
    outline_wanted = false
    M.close_outline()
    return
  end
  outline_wanted = true
  if not outline_available(editor_win()) then
    vim.notify("Flutter Outline: abre un archivo .dart (y espera a que cargue el LSP)", vim.log.levels.INFO)
    return
  end
  if not tree_win() then
    local cur = api.nvim_get_current_win()
    vim.cmd("NvimTreeOpen")
    M.dock_outline()
    if api.nvim_win_is_valid(cur) then api.nvim_set_current_win(cur) end
  else
    M.dock_outline()
  end
end

function M.setup()
  local g = api.nvim_create_augroup("sidebar", { clear = true })
  set_highlights()
  api.nvim_create_autocmd("ColorScheme", { group = g, callback = set_highlights })
  -- título en el árbol y el outline, se abran como se abran
  api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
    group = g, callback = function() vim.schedule(apply_titles) end,
  })
  local pending = false
  local function sync_later()
    if pending then return end
    pending = true
    vim.schedule(function() pending = false; sync() end)
  end
  api.nvim_create_autocmd("BufEnter", { group = g, callback = sync_later })
  -- llegó (o cambió) el outline del LSP
  api.nvim_create_autocmd("User", { group = g, pattern = "FlutterToolsOutlineChanged", callback = sync_later })
  -- si el árbol se cierra por otro lado (q, :NvimTreeClose) el outline se va con él
  api.nvim_create_autocmd("WinClosed", {
    group = g,
    callback = function(ev)
      local win = tonumber(ev.match)
      if win and api.nvim_win_is_valid(win) and vim.bo[api.nvim_win_get_buf(win)].filetype == "NvimTree" then
        vim.schedule(M.close_outline)
      end
    end,
  })
end

return M
