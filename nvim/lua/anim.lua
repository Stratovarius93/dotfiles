-- Animaciones de paneles (sin plugins): nvim-tree, terminal F1 y Trouble crecen de
-- verdad desde 1 columna/fila hasta su tamaño al abrirse, y se encogen antes de
-- cerrarse con M.toggle(). Las ventanas flotantes no se animan.
local M = {}
local api = vim.api

M.panel_ms = 240  -- abrir/cerrar paneles
M.interval = 8    -- ms entre cuadros (~120 fps; el terminal pinta lo que alcance)

-- paneles que se animan (filetype del buffer)
M.panels = { NvimTree = true, toggleterm = true, trouble = true }

local function ease_out(t) return 1 - (1 - t) ^ 3 end
local function ease_in_out(t) return t < 0.5 and 4 * t ^ 3 or 1 - (-2 * t + 2) ^ 3 / 2 end

-- Ejecuta frame(t) con t de 0 a 1 según el tiempo real; luego done().
local running = {}
local function animate(key, ms, frame, done)
  if running[key] then running[key]:stop(); running[key]:close(); running[key] = nil end
  local t0, timer = vim.uv.hrtime(), vim.uv.new_timer()
  running[key] = timer
  timer:start(0, M.interval, vim.schedule_wrap(function()
    if timer:is_closing() then return end
    local t = math.min((vim.uv.hrtime() - t0) / 1e6 / ms, 1)
    local ok = pcall(frame, t)
    if not ok or t >= 1 then
      timer:stop(); timer:close()
      if running[key] == timer then running[key] = nil end
      if done then pcall(done) end
    end
  end))
end

-- ¿El panel ocupa todo el ancho (abajo/arriba → se anima la altura) o no (lado → ancho)?
local function panel_dim(win)
  return api.nvim_win_get_width(win) >= vim.o.columns and "height" or "width"
end

local function get_size(win, dim)
  return dim == "width" and api.nvim_win_get_width(win) or api.nvim_win_get_height(win)
end

local function set_size(win, dim, n)
  if not api.nvim_win_is_valid(win) then error("closed") end
  if dim == "width" then api.nvim_win_set_width(win, n) else api.nvim_win_set_height(win, n) end
  -- con 1-2 columnas nvim desplaza la vista a la derecha para mostrar el cursor;
  -- sin esto el panel queda cortado ("ndroid", "ssets") al crecer
  -- (todas las ventanas de la columna: p. ej. nvim-tree + Flutter Outline debajo)
  if dim == "width" then
    local col = vim.fn.win_screenpos(win)[2]
    for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
      if api.nvim_win_get_config(w).relative == "" and vim.fn.win_screenpos(w)[2] == col then
        api.nvim_win_call(w, function()
          if vim.fn.winsaveview().leftcol ~= 0 then vim.fn.winrestview({ leftcol = 0 }) end
        end)
      end
    end
  end
end

local animated = {} -- ventanas de panel ya animadas al abrir

function M.panel_open(win)
  if animated[win] then return end
  animated[win] = true
  local dim = panel_dim(win)
  local target = get_size(win, dim)
  if target <= 2 then return end
  set_size(win, dim, 1)
  animate("panel" .. win, M.panel_ms, function(t)
    set_size(win, dim, math.max(1, math.floor(target * ease_out(t) + 0.5)))
  end, function() set_size(win, dim, target) end)
end

function M.panel_close(win, close)
  if not api.nvim_win_is_valid(win) then return close() end
  local dim = panel_dim(win)
  local from = get_size(win, dim)
  animate("panel" .. win, M.panel_ms * 0.8, function(t)
    set_size(win, dim, math.max(1, math.floor(from * (1 - ease_in_out(t)) + 0.5)))
  end, function()
    animated[win] = nil
    -- se restaura el tamaño antes de cerrar: algunos plugins lo recuerdan para la próxima vez
    pcall(set_size, win, dim, from)
    close()
  end)
end

-- Ventana (no flotante) del tab actual que muestra un buffer con ese filetype
-- (lazygit también es toggleterm, pero flotante: no es el panel de F1)
function M.find_panel(ft)
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_config(win).relative == ""
      and vim.bo[api.nvim_win_get_buf(win)].filetype == ft then return win end
  end
end

-- Toggle animado: si el panel está abierto se encoge y luego llama a close(); si no, open()
function M.toggle(ft, open, close)
  return function()
    local win = M.find_panel(ft)
    if win then M.panel_close(win, close) else open() end
  end
end

function M.setup()
  local g = api.nvim_create_augroup("anim", { clear = true })
  -- se espera un tick: el plugin termina de configurar la ventana (buffer, filetype, tamaño)
  local pending = false
  local function scan()
    if pending then return end
    pending = true
    vim.schedule(function()
      pending = false
      for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
        if api.nvim_win_is_valid(win) and api.nvim_win_get_config(win).relative == ""
          and M.panels[vim.bo[api.nvim_win_get_buf(win)].filetype] then
          M.panel_open(win)
        end
      end
    end)
  end
  api.nvim_create_autocmd({ "WinNew", "BufWinEnter", "FileType" }, { group = g, callback = scan })
  api.nvim_create_autocmd("WinClosed", {
    group = g,
    callback = function(ev)
      local win = tonumber(ev.match)
      if win then animated[win] = nil end
    end,
  })
  -- las ventanas que ya existían al cargar no se animan
  for _, win in ipairs(api.nvim_list_wins()) do animated[win] = true end
end

return M
