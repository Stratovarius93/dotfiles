-- F5: menú flotante de Flutter.
--  · App detenida → dispositivos disponibles (elige uno y corre la app) + emuladores para iniciar.
--  · App corriendo → Hot Reload, Hot Restart, Stop, DevTools, etc.
-- `flutter devices` tarda varios segundos: el menú abre al instante con los dispositivos
-- de la última búsqueda y se actualiza solo cuando termina la búsqueda nueva.

local M = {}
local nf = vim.g.have_nerd_font
local cache_file = vim.fn.stdpath("state") .. "/flutter-devices.json"

local function I(icon, fallback) return nf and icon or fallback end

local function read_cache()
  local ok, data = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(cache_file), "\n")) end)
  return ok and type(data) == "table" and data or { devices = {}, emulators = {} }
end

local function write_cache(data)
  pcall(vim.fn.writefile, { vim.json.encode(data) }, cache_file)
end

-- Ejecuta `flutter devices --machine` y `flutter emulators` (respeta fvm) en paralelo
local function scan(callback)
  require("flutter-tools.executable").flutter(function(cmd)
    local result, pending = { devices = {}, emulators = {} }, 2
    local function done()
      pending = pending - 1
      if pending == 0 then vim.schedule(function() callback(result) end) end
    end
    vim.system({ cmd, "devices", "--machine" }, { text = true }, function(r)
      local json = (r.stdout or ""):match("%[.*%]")
      local ok, list = pcall(vim.json.decode, json or "[]")
      for _, d in ipairs(ok and list or {}) do
        if d.isSupported ~= false then
          table.insert(result.devices, {
            id = d.id, name = d.name, platform = d.targetPlatform or "", emulator = d.emulator, sdk = d.sdk or "",
          })
        end
      end
      done()
    end)
    vim.system({ cmd, "emulators" }, { text = true }, function(r)
      for _, line in ipairs(vim.split(r.stdout or "", "\n")) do
        local parts = vim.split(line, "•")
        if #parts == 4 and vim.trim(parts[1]) ~= "Id" then
          table.insert(result.emulators, { id = vim.trim(parts[1]), name = vim.trim(parts[2]), platform = vim.trim(parts[4]) })
        end
      end
      done()
    end)
  end)
end

-- .vscode/launch.json (JSON con comentarios y comas finales, como lo acepta VS Code)
local function strip_jsonc(text)
  local out, i, n, in_str = {}, 1, #text, false
  while i <= n do
    local c, nx = text:sub(i, i), text:sub(i + 1, i + 1)
    if in_str then
      table.insert(out, c)
      if c == "\\" then table.insert(out, nx); i = i + 1 elseif c == '"' then in_str = false end
    elseif c == '"' then in_str = true; table.insert(out, c)
    elseif c == "/" and nx == "/" then while i <= n and text:sub(i, i) ~= "\n" do i = i + 1 end; i = i - 1
    elseif c == "/" and nx == "*" then local e = text:find("*/", i + 2, true) or n; i = e + 1
    else table.insert(out, c) end
    i = i + 1
  end
  return (table.concat(out):gsub(",(%s*[%]}])", "%1"))
end

local function project_root()
  return vim.fs.root(0, { "pubspec.yaml" }) or vim.fn.getcwd()
end

-- Entornos de launch.json convertidos a configuraciones de flutter-tools
local function launch_configs()
  local root = project_root()
  local file = root .. "/.vscode/launch.json"
  if vim.fn.filereadable(file) == 0 then return {} end
  local ok, data = pcall(vim.json.decode, strip_jsonc(table.concat(vim.fn.readfile(file), "\n")))
  if not ok or type(data) ~= "table" then
    vim.notify("No se pudo leer .vscode/launch.json", vim.log.levels.WARN)
    return {}
  end
  local list = {}
  for _, c in ipairs(data.configurations or {}) do
    if c.type == "dart" and (c.request or "launch") == "launch" then
      local conf = { name = c.name, target = c.program, flutter_mode = c.flutterMode, additional_args = {} }
      if c.cwd then conf.cwd = (c.cwd:gsub("%${workspaceFolder}", root)) end
      local args = vim.list_extend(vim.deepcopy(c.toolArgs or {}), c.args or {})
      local i = 1
      while i <= #args do
        local a = args[i]
        if a == "--flavor" then conf.flavor = args[i + 1]; i = i + 1
        elseif a:match("^%-%-flavor=") then conf.flavor = a:match("=(.*)")
        else table.insert(conf.additional_args, a) end
        i = i + 1
      end
      table.insert(list, conf)
    end
  end
  return list
end

-- Sin launch.json: detectar flavors del proyecto
--  · Android: bloque productFlavors de android/app/build.gradle(.kts)
--  · iOS: esquemas de ios/Runner.xcodeproj (menos Runner y extensiones)
--  · target: lib/**/main_<flavor>.dart si existe
local function android_flavors(root)
  for _, f in ipairs({ "/android/app/build.gradle", "/android/app/build.gradle.kts" }) do
    if vim.fn.filereadable(root .. f) == 1 then
      local text = table.concat(vim.fn.readfile(root .. f), "\n")
      local start = text:find("productFlavors%s*{")
      if not start then return {} end
      local i = text:find("{", start, true) + 1
      local depth, names, line_start = 1, {}, i
      while i <= #text and depth > 0 do
        local c = text:sub(i, i)
        if c == "{" then
          if depth == 1 then
            local head = text:sub(line_start, i - 1)
            local name = head:match("([%w_]+)%s*$") -- groovy: dev {
              or head:match('create%s*%(%s*"([%w_]+)"%s*%)') -- kts: create("dev") {
              or head:match('register%s*%(%s*"([%w_]+)"%s*%)')
            if name then table.insert(names, name) end
          end
          depth = depth + 1
        elseif c == "}" then
          depth = depth - 1
          if depth == 1 then line_start = i + 1 end
        elseif c == "\n" and depth == 1 then
          line_start = i + 1
        end
        i = i + 1
      end
      return names
    end
  end
  return {}
end

local function ios_flavors(root)
  local names = {}
  local dir = root .. "/ios/Runner.xcodeproj/xcshareddata/xcschemes"
  for _, f in ipairs(vim.fn.glob(dir .. "/*.xcscheme", false, true)) do
    local name = vim.fn.fnamemodify(f, ":t:r")
    local is_ext = name:find("Extension") or name:find("Service") or name:find("Widget")
      or name:find("Notification") or name:find("Intent") or name:find("Share") or name:find("Tests")
    if name ~= "Runner" and not is_ext then table.insert(names, name) end
  end
  return names
end

local function detected_configs(root, platform)
  local android, ios = android_flavors(root), ios_flavors(root)
  local on = { android = {}, ios = {} }
  for _, n in ipairs(android) do on.android[n] = true end
  for _, n in ipairs(ios) do on.ios[n] = true end
  local order, seen = {}, {}
  for _, n in ipairs(vim.list_extend(vim.deepcopy(android), ios)) do
    if not seen[n] then seen[n] = true; table.insert(order, n) end
  end
  local list = {}
  for _, n in ipairs(order) do
    -- solo los flavors que existen para la plataforma del dispositivo
    local ok_platform = (platform:find("android") and on.android[n]) or (platform:find("ios") and on.ios[n])
      or not (platform:find("android") or platform:find("ios"))
    if ok_platform then
      local target = vim.fs.find("main_" .. n .. ".dart", { path = root .. "/lib", type = "file" })[1]
      local where = (on.android[n] and on.ios[n]) and "android+ios" or on.android[n] and "android" or "ios"
      table.insert(list, {
        name = n, flavor = n, flutter_mode = "debug", additional_args = {},
        target = target and target:sub(#root + 2) or nil, -- relativo a la raíz del proyecto
        source = where,
      })
    end
  end
  return list
end

local last_conf = {} -- proyecto -> nombre del último entorno usado

local function pick_config(device, callback)
  local root = project_root()
  local confs, source = launch_configs(), ".vscode/launch.json"
  if #confs == 0 then
    confs, source = detected_configs(root, device.platform or ""), "flavors detectados"
  end
  if #confs == 0 then return callback(nil) end
  if #confs == 1 then return callback(confs[1]) end
  -- el último entorno usado va primero; el resto en el orden del archivo
  for i, c in ipairs(confs) do
    if c.name == last_conf[root] then table.insert(confs, 1, table.remove(confs, i)) break end
  end
  local pickers, actions, state = require("telescope.pickers"), require("telescope.actions"), require("telescope.actions.state")
  local finders, conf = require("telescope.finders"), require("telescope.config").values
  local displayer = require("telescope.pickers.entry_display").create({ separator = " ", items = { { width = 30 }, { remaining = true } } })
  pickers.new(require("telescope.themes").get_dropdown({ layout_config = { width = 70, height = 12 } }), {
    prompt_title = "Entorno para " .. device.name .. "  (" .. source .. ")",
    finder = finders.new_table({
      results = confs,
      entry_maker = function(c)
        local detail = table.concat(vim.tbl_filter(function(x) return x ~= nil and x ~= "" end, {
          c.flavor and ("flavor " .. c.flavor), c.flutter_mode,
          c.target and vim.fn.fnamemodify(c.target, ":t") or (c.source and "lib/main.dart"), c.source,
        }), " · ")
        return {
          value = c, ordinal = c.name,
          display = function() return displayer({ I("󰒓", "*") .. " " .. c.name, { detail, "Comment" } }) end,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(bufnr)
      actions.select_default:replace(function()
        local entry = state.get_selected_entry()
        actions.close(bufnr)
        if entry then
          last_conf[root] = entry.value.name
          callback(entry.value)
        end
      end)
      return true
    end,
  }):find()
end

local current_conf_name

local function run_on(device)
  pick_config(device, function(c)
    local commands = require("flutter-tools.commands")
    local dev = { id = device.id, name = device.name }
    current_conf_name = c and c.name or nil
    if c then
      c = vim.deepcopy(c)
      c.device = device.id
      commands.run({ device = dev }, c)
    else
      commands.run({ device = dev })
    end
  end)
end

local function device_icon(d)
  local p = d.platform or ""
  if p:find("ios") then return I("", "") end
  if p:find("android") then return I("", "") end
  if p:find("web") then return I("󰖟", "") end
  if p:find("darwin") or p:find("macos") then return I("", "") end
  return I("󰟀", "")
end

-- Entradas cuando la app está detenida
local function idle_entries(data, searching)
  local items = {}
  for _, d in ipairs(data.devices or {}) do
    local p = d.platform or ""
    local kind = d.emulator and "simulador" or p:find("web") and "navegador"
      or (p:find("darwin") or p:find("linux") or p:find("windows")) and "escritorio" or "físico"
    table.insert(items, {
      text = ("%s %s"):format(device_icon(d), d.name),
      detail = ("%s · %s"):format(d.platform, kind),
      action = function() run_on(d) end,
    })
  end
  -- emuladores que no están ya encendidos
  local running = {}
  for _, d in ipairs(data.devices or {}) do running[d.name] = true end
  for _, e in ipairs(data.emulators or {}) do
    if not running[e.name] then
      table.insert(items, {
        text = ("%s Iniciar %s"):format(I("󰐊", ">"), e.name),
        detail = (e.platform or "") .. " · apagado",
        action = function()
          require("flutter-tools.devices").launch_emulator({ id = e.id, name = e.name })
          vim.notify("Iniciando " .. e.name .. "… luego presiona F5 otra vez")
        end,
      })
    end
  end
  if searching then
    table.insert(items, { text = I("󰑐", "~") .. " Buscando dispositivos…", detail = "", action = function() end })
  elseif #items == 0 then
    table.insert(items, { text = "No hay dispositivos", detail = "conecta uno o inicia un emulador", action = function() end })
  end
  return items
end

-- Entradas cuando la app está corriendo
local function running_entries()
  local c = require("flutter-tools.commands")
  local cmd = function(name) return function() vim.cmd(name) end end
  return {
    { text = I("󰑓", "*") .. " Hot Reload", detail = "F6", action = function() c.reload() end },
    { text = I("󰜉", "*") .. " Hot Restart", detail = "F7", action = function() c.restart() end },
    { text = I("󰓛", "*") .. " Stop", detail = "F8", action = function() c.quit() end },
    { text = I("󰖟", "*") .. " Abrir DevTools en el navegador", detail = "", action = function() c.open_dev_tools() end },
    { text = I("󰆏", "*") .. " Copiar URL del profiler", detail = "", action = function() c.copy_profiler_url() end },
    { text = I("󰦪", "*") .. " Logs", detail = "F2", action = cmd("FlutterLogToggle") },
    { text = I("󰈈", "*") .. " Inspeccionar widget", detail = "toggle", action = function() c.inspect_widget() end },
    { text = I("󰉦", "*") .. " Debug paint", detail = "toggle", action = function() c.visual_debug() end },
    { text = I("󰄨", "*") .. " Performance overlay", detail = "toggle", action = function() c.performance_overlay() end },
    { text = I("󰸱", "*") .. " Repaint rainbow", detail = "toggle", action = function() c.repaint_rainbow() end },
    { text = I("󰾆", "*") .. " Animaciones lentas", detail = "toggle", action = function() c.slow_animations() end },
    { text = I("󰔎", "*") .. " Cambiar brillo (claro/oscuro)", detail = "toggle", action = function() c.brightness() end },
    { text = I("󰌙", "*") .. " Desconectar (dejar la app corriendo)", detail = "detach", action = function() c.detach() end },
  }
end

local function make_finder(items)
  local finders = require("telescope.finders")
  local entry_display = require("telescope.pickers.entry_display")
  local displayer = entry_display.create({ separator = " ", items = { { width = 40 }, { remaining = true } } })
  return finders.new_table({
    results = items,
    entry_maker = function(item)
      return {
        value = item,
        ordinal = item.text .. " " .. item.detail,
        display = function() return displayer({ item.text, { item.detail, "Comment" } }) end,
      }
    end,
  })
end

function M.open()
  local ok_tools = pcall(require, "flutter-tools")
  if not ok_tools then return vim.notify("flutter-tools no está disponible", vim.log.levels.WARN) end
  local pickers = require("telescope.pickers")
  local actions, state = require("telescope.actions"), require("telescope.actions.state")
  local conf = require("telescope.config").values
  local commands = require("flutter-tools.commands")

  local is_running = commands.is_running()
  local title, items
  if is_running then
    local dev = commands.current_device()
    title = "Flutter · corriendo" .. (current_conf_name and (" " .. current_conf_name) or "")
      .. (dev and dev.name and (" en " .. dev.name) or "")
    items = running_entries()
  else
    title = "Flutter · elige dispositivo para correr"
    items = idle_entries(read_cache(), true)
  end

  local picker = pickers.new(require("telescope.themes").get_dropdown({
    layout_config = { width = 70, height = 18 },
  }), {
    prompt_title = title,
    finder = make_finder(items),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(bufnr)
      actions.select_default:replace(function()
        local entry = state.get_selected_entry()
        actions.close(bufnr)
        if entry then entry.value.action() end
      end)
      return true
    end,
  })
  picker:find()

  if not is_running then
    scan(function(data)
      write_cache(data)
      if picker.prompt_bufnr and vim.api.nvim_buf_is_valid(picker.prompt_bufnr) then
        picker:refresh(make_finder(idle_entries(data, false)), { reset_prompt = false })
      end
    end)
  end
end

return M
