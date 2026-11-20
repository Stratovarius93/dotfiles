-- Neovim config: Gruvbox Flutter + Flutter/Dart (portado de Antigravity)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- Iconos de archivo (Symbols Nerd Font). Ponlo en false si se ven cuadros o "?"
vim.g.have_nerd_font = true
vim.o.showmode = false -- el modo ya se ve en lualine
vim.g.loaded_netrw = 1      -- nvim-tree reemplaza al explorador netrw
vim.g.loaded_netrwPlugin = 1

-- ── Opciones ─────────────────────────────────────────────
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.signcolumn = "yes"
vim.o.clipboard = "unnamedplus"   -- vim.useSystemClipboard
vim.o.hlsearch = true             -- vim.hlsearch
vim.o.incsearch = true            -- vim.incsearch
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.termguicolors = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.colorcolumn = "80"          -- dart.lineLength
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.timeoutlen = 400
vim.o.updatetime = 250

-- ── lazy.nvim ────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Tema
  {
    "Stratovarius93/gruvbox-flutter-theme",
    name = "gruvbox-flutter",
    lazy = false,
    priority = 1000,
    config = function() vim.cmd.colorscheme("gruvbox-flutter") end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "dart", "lua", "markdown", "markdown_inline", "json", "yaml" },
        sync_install = true,
        highlight = { enable = true },
      })
    end,
  },

  -- Flutter / Dart (Dart-Code + Flutter): LSP, hot reload, guías de widgets
  {
    "nvim-flutter/flutter-tools.nvim",
    ft = "dart",
    dependencies = { "nvim-lua/plenary.nvim", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      require("flutter-tools").setup({
        fvm = true,                                   -- dart.flutterSdkPath = .fvm
        widget_guides = { enabled = true },           -- previewFlutterUiGuides
        closing_tags = { enabled = true },
        dev_log = { enabled = true, open_cmd = "botright 15split" },
        lsp = {
          capabilities = require("cmp_nvim_lsp").default_capabilities(),
          settings = { lineLength = 80, enableSnippets = true },
        },
      })
    end,
  },

  -- Autocompletado (Ctrl+j / Ctrl+k en sugerencias)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets", -- incluye snippets de Flutter
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        preselect = cmp.PreselectMode.Item,      -- suggestSelection = first
        completion = { completeopt = "menu,menuone,noinsert" },
        mapping = cmp.mapping.preset.insert({
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<Tab>"] = cmp.mapping(function(fallback)  -- tabCompletion = onlySnippets
            if luasnip.expand_or_jumpable() then luasnip.expand_or_jump() else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then luasnip.jump(-1) else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources(
          { { name = "nvim_lsp" }, { name = "luasnip" }, { name = "path" } },
          { { name = "buffer" } }
        ),
      })
    end,
  },

  -- Buscador (Quick Open / fzf / paleta de comandos)
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      defaults = {
        mappings = { i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
        } },
        -- Imágenes en la vista previa con chafa (caracteres de color; Warp no muestra imágenes reales en nvim)
        preview = {
          mime_hook = function(filepath, bufnr, opts)
            local ext = (filepath:match("%.(%w+)$") or ""):lower()
            local images = { png = true, jpg = true, jpeg = true, gif = true, webp = true, bmp = true, ico = true }
            if images[ext] and vim.fn.executable("chafa") == 1 then
              local win = opts.winid
              local size = vim.api.nvim_win_get_width(win) .. "x" .. vim.api.nvim_win_get_height(win)
              local term = vim.api.nvim_open_term(bufnr, {})
              vim.fn.jobstart({ "chafa", "--format=symbols", "--animate=off", "--size=" .. size, filepath }, {
                stdout_buffered = true,
                on_stdout = function(_, data)
                  if vim.api.nvim_buf_is_valid(bufnr) then
                    pcall(vim.api.nvim_chan_send, term, table.concat(data, "\r\n"))
                  end
                end,
              })
            else
              require("telescope.previewers.utils").set_preview_message(bufnr, opts.winid, "Binary cannot be previewed")
            end
          end,
        },
      },
    },
  },

  -- Git (GitLens + Git Blame)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = { current_line_blame = true },
  },

  -- EasyMotion
  { "folke/flash.nvim", event = "VeryLazy", opts = {} },

  -- Panel de problemas (como Problems de VS Code): F4
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = { focus = true },
    keys = {
      { "<F4>", "<cmd>Trouble diagnostics toggle<cr>", desc = "Problemas del proyecto" },
      { "<S-F4>", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Problemas del archivo" },
    },
  },

  -- Barra lateral de archivos estilo NERDTree (a la derecha, sin Nerd Font)
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false, -- para que `nvim .` abra el árbol en vez de netrw
    dependencies = { { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font } },
    config = function()
      local api = require("nvim-tree.api")

      -- Atajos estilo NERDTree, encima de los de nvim-tree
      local function on_attach(bufnr)
        api.config.mappings.default_on_attach(bufnr)
        local m = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, nowait = true, silent = true, desc = "Tree: " .. desc })
        end
        m("o", api.node.open.edit, "Abrir")
        m("s", api.node.open.vertical, "Abrir en split vertical")
        m("<S-CR>", api.node.open.vertical, "Abrir a la derecha (split vertical)")
        m("i", api.node.open.horizontal, "Abrir en split horizontal")
        m("x", api.node.navigate.parent_close, "Cerrar carpeta padre")
        m("u", api.tree.change_root_to_parent, "Subir un nivel")
        m("C", api.tree.change_root_to_node, "Entrar como raíz")
        m("I", api.tree.toggle_hidden_filter, "Mostrar/ocultar ocultos")
        m("R", api.tree.reload, "Refrescar")
        m("q", api.tree.close, "Cerrar árbol")
        m("?", api.tree.toggle_help, "Ayuda")
      end

      require("nvim-tree").setup({
        on_attach = on_attach,
        hijack_cursor = true,
        sync_root_with_cwd = true,
        update_focused_file = { enable = true }, -- resalta el archivo abierto
        view = { side = "right", width = 35, preserve_window_proportions = true },
        filters = { custom = { "^.git$", "^.dart_tool$" } },
        renderer = {
          root_folder_label = ":t",      -- solo el nombre del proyecto
          highlight_git = "name",
          highlight_opened_files = "name",
          indent_width = 2,
          -- Líneas guía de la estructura (│ ├ └) debajo de cada carpeta abierta
          indent_markers = {
            enable = true,
            inline_arrows = true,
            icons = { corner = "└", edge = "│", item = "├", bottom = "─", none = " " },
          },
          icons = {
            show = {
              file = vim.g.have_nerd_font, folder = vim.g.have_nerd_font,
              folder_arrow = true, git = true, modified = true,
            },
            git_placement = "after",
            glyphs = {
              modified = "●",
              folder = { arrow_closed = "▸", arrow_open = "▾" },
              git = {
                unstaged = "✹", staged = "✚", unmerged = "═", renamed = "➜",
                untracked = "✭", deleted = "✖", ignored = "☒",
              },
            },
          },
        },
        modified = { enable = true },
        diagnostics = {
          enable = true,
          show_on_dirs = true,
          icons = { error = "✖", warning = "▲", info = "●", hint = "◆" },
        },
        actions = { open_file = {
          quit_on_open = false, resize_window = true,
          -- Sin "Pick window:": abrir en el último panel usado aunque haya splits
          window_picker = { enable = false },
        } },
      })

      -- Si el árbol queda como única ventana, cerrar Neovim (como NERDTree)
      vim.api.nvim_create_autocmd("QuitPre", {
        callback = function()
          local wins = vim.tbl_filter(function(w)
            return vim.api.nvim_win_get_config(w).relative == ""
          end, vim.api.nvim_list_wins())
          if #wins == 2 then
            for _, w in ipairs(wins) do
              if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "NvimTree" then
                api.tree.close()
              end
            end
          end
        end,
      })
    end,
  },

  -- Barra de estado (modo, rama, errores/warnings, tipo de archivo)
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font } },
    opts = function()
      local p = require("gruvbox-flutter").palette
      local function mode(color)
        return {
          a = { fg = p.bg0, bg = color, gui = "bold" },
          b = { fg = p.fg, bg = p.bg4 },
          c = { fg = p.fg_soft, bg = p.bg1 },
        }
      end
      local nf = vim.g.have_nerd_font
      return {
        options = {
          theme = {
            normal = mode(p.blue),
            insert = mode(p.green),
            visual = mode(p.purple),
            replace = mode(p.red),
            command = mode(p.yellow),
            terminal = mode(p.aqua),
            inactive = {
              a = { fg = p.grey1, bg = p.bg1 },
              b = { fg = p.grey1, bg = p.bg1 },
              c = { fg = p.grey1, bg = p.bg1 },
            },
          },
          globalstatus = true,
          icons_enabled = nf,
          component_separators = nf and { left = "", right = "" } or { left = "|", right = "|" },
          section_separators = nf and { left = "", right = "" } or { left = "", right = "" },
          disabled_filetypes = { statusline = { "NvimTree" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff" },
          lualine_c = {
            { "diagnostics", symbols = nf and { error = " ", warn = " ", info = " ", hint = "󰌵 " }
              or { error = "E", warn = "W", info = "I", hint = "H" } },
            { "filename", path = 1 },
          },
          lualine_x = { "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        extensions = { "nvim-tree", "toggleterm", "lazy", "trouble" },
      }
    end,
  },

  -- Tabs (buffers abiertos arriba, como las pestañas del IDE)
  {
    "akinsho/bufferline.nvim",
    version = "*",
    lazy = false,
    opts = {
      options = {
        mode = "buffers",
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(count, level)
          return (level:match("error") and " ✖" or " ▲") .. count
        end,
        show_buffer_icons = vim.g.have_nerd_font,
        show_buffer_close_icons = true,
        show_close_icon = false,
        buffer_close_icon = "×",
        modified_icon = "●",
        close_icon = "×",
        left_trunc_marker = "◂",
        right_trunc_marker = "▸",
        separator_style = "thin",
        always_show_bufferline = true,
        offsets = {
          { filetype = "NvimTree", text = "Archivos", text_align = "center", separator = true },
        },
        close_command = function(n) require("bufferline").unpin_and_close(n) end,
      },
    },
  },

  -- Cobertura de tests (Coverage Gutters)
  {
    "andythigpen/nvim-coverage",
    cmd = { "Coverage", "CoverageLoad", "CoverageToggle", "CoverageSummary", "CoverageClear" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      auto_reload = true,
      lcov_file = "coverage/lcov.info",
      highlights = {
        covered = { fg = "#a9b665" },
        uncovered = { fg = "#ea6962" },
        partial = { fg = "#d8a657" },
      },
    },
  },

  -- Explorador en columnas estilo Ranger, editable como texto (- abre en el archivo actual)
  {
    "echasnovski/mini.files",
    version = false,
    dependencies = { { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font } },
    keys = {
      { "-", function()
          local mf = require("mini.files")
          if not mf.close() then
            local file = vim.api.nvim_buf_get_name(0)
            mf.open(vim.fn.filereadable(file) == 1 and file or vim.fn.getcwd())
            mf.reveal_cwd()
          end
        end, desc = "mini.files (explorador en columnas)" },
    },
    opts = {
      content = { prefix = not vim.g.have_nerd_font and function() return "", "" end or nil },
      mappings = { go_in_plus = "<CR>", synchronize = "=" },
      windows = { preview = true, width_focus = 30, width_preview = 50 },
    },
  },
  -- Scroll suave para <C-d> <C-u> <C-f> <C-b> <C-e> <C-y> zz zt zb
  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {
      duration_multiplier = 1.0,
      easing = "quadratic",
      hide_cursor = true,
      respect_scrolloff = true,
    },
  },
  -- Terminal (F1)
  {
    "akinsho/toggleterm.nvim",
    cmd = "ToggleTerm",
    keys = { { "<F1>", "<cmd>ToggleTerm<cr>", mode = { "n", "t" }, desc = "Terminal" } },
    opts = { direction = "horizontal", size = 15 },
  },
}, { install = { colorscheme = { "gruvbox-flutter" } } })

-- ── Diagnósticos inline (Error Lens) ─────────────────────
-- Estilo Error Lens: fondo de color en la línea con error/warning + mensaje al final
local function errorlens_highlights()
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg or 0x282828
  local function blend(fg, alpha)
    local out = 0
    for shift = 16, 0, -8 do
      local a, b = bit.band(bit.rshift(fg, shift), 0xff), bit.band(bit.rshift(bg, shift), 0xff)
      out = out + bit.lshift(math.floor(a * alpha + b * (1 - alpha) + 0.5), shift)
    end
    return out
  end
  for _, sev in ipairs({ "Error", "Warn", "Info", "Hint" }) do
    local fg = vim.api.nvim_get_hl(0, { name = "DiagnosticVirtualText" .. sev, link = false }).fg
      or vim.api.nvim_get_hl(0, { name = "Diagnostic" .. sev, link = false }).fg
    if fg then
      vim.api.nvim_set_hl(0, "ErrorLensLine" .. sev, { bg = blend(fg, 0.18) })
      vim.api.nvim_set_hl(0, "DiagnosticVirtualText" .. sev, { fg = fg, bg = blend(fg, 0.18), italic = true })
    end
  end
end
errorlens_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = errorlens_highlights })

local S = vim.diagnostic.severity
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 4 },
  signs = {
    linehl = {
      [S.ERROR] = "ErrorLensLineError",
      [S.WARN] = "ErrorLensLineWarn",
      [S.INFO] = "ErrorLensLineInfo",
      [S.HINT] = "ErrorLensLineHint",
    },
  },
  severity_sort = true,
  float = { border = "rounded" },
})

-- ── Format on save para Dart ─────────────────────────────
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.dart",
  callback = function() vim.lsp.buf.format({ async = false }) end,
})

-- ── Keymaps ──────────────────────────────────────────────
local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- Insert: jk / kj → Esc
map("i", "jk", "<Esc>", "Salir de insert")
map("i", "kj", "<Esc>", "Salir de insert")

-- Tabs (Tab / ` = siguiente / anterior, en el orden de la barra)
map("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", "Tab siguiente")
map("n", "`", "<cmd>BufferLineCyclePrev<cr>", "Tab anterior")
map("n", "<leader><", "<cmd>BufferLineMovePrev<cr>", "Mover tab a la izquierda")
map("n", "<leader>>", "<cmd>BufferLineMoveNext<cr>", "Mover tab a la derecha")
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", "Cerrar las demás tabs")
map("n", "<leader>bp", "<cmd>BufferLinePick<cr>", "Elegir tab por letra")
for _, i in ipairs({ 1, 2, 3, 4, 5, 7, 8, 9 }) do -- <leader>6 = seleccionar bloque
  map("n", "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<cr>", "Ir a tab " .. i)
end

-- Cerrar la tab sin romper el layout (el árbol no ocupa la ventana del editor)
local function close_buffer()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].modified then
    return vim.notify("Hay cambios sin guardar (<leader>w)", vim.log.levels.WARN)
  end
  -- Si hay un split (p. ej. definición abierta a la derecha), cerrar ese panel
  -- y quitar su tab si el archivo ya no se ve en ningún otro panel
  local editor_wins = vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative == ""
      and vim.bo[vim.api.nvim_win_get_buf(w)].filetype ~= "NvimTree"
  end, vim.api.nvim_tabpage_list_wins(0))
  if #editor_wins > 1 then
    vim.api.nvim_win_close(0, false)
    if #vim.fn.win_findbuf(buf) == 0 then pcall(vim.api.nvim_buf_delete, buf, {}) end
    return
  end
  local listed = vim.tbl_filter(function(b) return vim.bo[b].buflisted end, vim.api.nvim_list_bufs())
  if #listed > 1 then vim.cmd("BufferLineCyclePrev") else vim.cmd("enew") end
  pcall(vim.api.nvim_buf_delete, buf, {})
end

-- Guardar / cerrar (movidos a <leader> para no pisar w y q de Vim)
map("n", "<leader>w", "<cmd>w<cr>", "Guardar")
map("n", "<leader>W", "<cmd>wa<cr>", "Guardar todo")
map("n", "<leader>q", close_buffer, "Cerrar tab")
-- q = cerrar tab, Q = cerrar todo y salir (pregunta si hay cambios sin guardar)
map("n", "q", close_buffer, "Cerrar tab")
map("n", "Q", "<cmd>confirm qa<cr>", "Cerrar todo y salir")
-- Grabar macros (antes q): <leader>m + registro, p. ej. <leader>ma … <leader>m, luego @a
map("n", "<leader>m", "q", "Grabar macro")

-- Scroll: <C-d>/<C-u>/<C-f>/<C-b>/<C-e>/<C-y>/zz/zt/zb los anima neoscroll.nvim (ver plugins)

-- Quitar resaltado de búsqueda
map("n", "<C-n>", "<cmd>nohlsearch<cr>", "Quitar resaltado")

-- Coma / punto y coma al final de la línea (movidos a <leader> para no pisar , y ; de Vim)
map("n", "<leader>,", "A,<Esc>", "Coma al final")
map("n", "<leader>;", "A;<Esc>", "Punto y coma al final")

-- Comentar (gcc / gc nativos)
vim.keymap.set("n", "<leader>ci", "gcc", { remap = true, desc = "Comentar línea" })
vim.keymap.set("x", "<leader>ci", "gc", { remap = true, desc = "Comentar selección" })

-- Seleccionar bloque con %
map("n", "<leader>6", "^v%", "Seleccionar bloque desde inicio de línea")
map("n", "<leader>^", "bv%", "Seleccionar bloque desde palabra")

-- Movimiento entre splits (Cmd+h/j/k/l en Antigravity)
map("n", "<C-h>", "<C-w>h", "Split izquierdo")
map("n", "<C-j>", "<C-w>j", "Split abajo")
map("n", "<C-k>", "<C-w>k", "Split arriba")
map("n", "<C-l>", "<C-w>l", "Split derecho")

-- Buscador
map("n", "<leader>f", "<cmd>Telescope find_files<cr>", "Buscar archivo")
map("n", "<leader>F", "<cmd>Telescope live_grep<cr>", "Buscar texto")
map("n", "<leader>/", "<cmd>Telescope commands<cr>", "Paleta de comandos")
map("n", "<leader>S", ":%s//g<Left><Left>", "Buscar y reemplazar")

-- Ranger flotante: abre los archivos elegidos (Enter o l) como tabs de nvim
local function open_ranger()
  local chosen = vim.fn.tempname()
  local current = vim.fn.expand("%:p")
  local cmd = { "ranger", "--choosefiles=" .. chosen }
  if current ~= "" and vim.fn.filereadable(current) == 1 then
    table.insert(cmd, "--selectfile=" .. current)
  else
    table.insert(cmd, vim.fn.getcwd())
  end
  local term = require("toggleterm.terminal").Terminal:new({
    cmd = table.concat(vim.tbl_map(vim.fn.shellescape, cmd), " "),
    direction = "float",
    float_opts = { border = "rounded", width = math.floor(vim.o.columns * 0.9), height = math.floor(vim.o.lines * 0.85) },
    on_open = function() vim.cmd("startinsert") end,
    on_exit = function(t)
      vim.schedule(function()
        if t:is_open() then t:close() end
        if vim.fn.filereadable(chosen) == 0 then return end
        for _, file in ipairs(vim.fn.readfile(chosen)) do
          if vim.fn.isdirectory(file) == 0 then vim.cmd("edit " .. vim.fn.fnameescape(file)) end
        end
        vim.fn.delete(chosen)
      end)
    end,
  })
  term:toggle()
end
map("n", "<leader>o", open_ranger, "Ranger (explorador flotante)")

-- Barra lateral
map("n", "<leader>n", "<cmd>NvimTreeToggle<cr>", "Mostrar/ocultar explorador")
map("n", "<leader>e", "<cmd>NvimTreeFocus<cr>", "Foco en explorador")

-- EasyMotion → flash
map({ "n", "x", "o" }, "<leader>s", function() require("flash").jump() end, "Flash jump")

-- Diagnósticos (Alt+j / Alt+k)
map("n", "<M-j>", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Error siguiente")
map("n", "<M-k>", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Error anterior")

-- LSP (se activan al conectar el servidor)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local b = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
    end
    b("gd", vim.lsp.buf.definition, "Ir a definición")
    b("<leader>gd", "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>", "Definición en split")
    b("<leader>x", vim.lsp.buf.hover, "Hover / preview")
    b("<leader>i", "<cmd>Telescope lsp_references<cr>", "Referencias")
    b("<leader>a", vim.lsp.buf.code_action, "Quick fix")
    b("<leader>rn", vim.lsp.buf.rename, "Renombrar")
  end,
})

-- Flutter (hot reload, debug, logs)
map("n", "<leader>d", "<cmd>FlutterRun<cr>", "Flutter run")
map("n", "<leader>r", "<cmd>FlutterReload<cr>", "Hot reload")
map("n", "<leader>R", "<cmd>FlutterRestart<cr>", "Hot restart")
map("n", "<F6>", "<cmd>FlutterReload<cr>", "Hot reload")
map("n", "<F7>", "<cmd>FlutterRestart<cr>", "Hot restart")
map("n", "<F8>", "<cmd>FlutterQuit<cr>", "Detener app")
map("n", "<F2>", "<cmd>FlutterLogToggle<cr>", "Logs Flutter")

-- Cobertura: correr tests con cobertura y pintar el gutter
local function project_root()
  return vim.fs.root(0, { "pubspec.yaml", ".git" }) or vim.fn.getcwd()
end

vim.api.nvim_create_user_command("FlutterTestCoverage", function()
  local root = project_root()
  local flutter = vim.uv.fs_stat(root .. "/.fvm") and { "fvm", "flutter" } or { "flutter" }
  local cmd = vim.list_extend(flutter, { "test", "--coverage" })
  vim.notify("Corriendo " .. table.concat(cmd, " ") .. "…")
  vim.system(cmd, { cwd = root }, vim.schedule_wrap(function(res)
    if res.code ~= 0 then
      vim.notify("Tests fallaron (código " .. res.code .. ")", vim.log.levels.WARN)
    end
    vim.cmd("cd " .. vim.fn.fnameescape(root))
    require("coverage").load(true)
  end))
end, { desc = "flutter test --coverage y cargar lcov" })

map("n", "<leader>tc", "<cmd>FlutterTestCoverage<cr>", "Tests con cobertura")
map("n", "<leader>tl", "<cmd>CoverageLoad<cr><cmd>CoverageShow<cr>", "Cargar cobertura existente")
map("n", "<leader>tt", "<cmd>CoverageToggle<cr>", "Mostrar/ocultar cobertura")
map("n", "<leader>ts", "<cmd>CoverageSummary<cr>", "Resumen de cobertura")

-- Vista previa de imágenes (Gutter Preview) con Quick Look de macOS
local image_ext = { png = 1, jpg = 1, jpeg = 1, gif = 1, webp = 1, bmp = 1, svg = 1, ico = 1 }

local function preview_image_under_cursor()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".")
  local path
  -- busca la ruta entre comillas que contiene el cursor
  for s, p, e in line:gmatch("()['\"]([^'\"]+)['\"]()") do
    if col >= s and col < e then path = p break end
  end
  path = path or vim.fn.expand("<cfile>")
  local ext = (path:match("%.(%w+)$") or ""):lower()
  if not image_ext[ext] then
    return vim.notify("No hay ruta de imagen bajo el cursor", vim.log.levels.INFO)
  end
  local candidates = { path, project_root() .. "/" .. path, vim.fn.expand("%:p:h") .. "/" .. path }
  for _, f in ipairs(candidates) do
    if vim.uv.fs_stat(f) then
      vim.system({ "qlmanage", "-p", vim.fn.fnamemodify(f, ":p") }, { stdout = false, stderr = false })
      return
    end
  end
  vim.notify("No se encontró: " .. path, vim.log.levels.WARN)
end

map("n", "<leader>p", preview_image_under_cursor, "Previsualizar imagen")

-- Abrir un archivo de imagen directamente → Quick Look en vez de binario
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.bmp", "*.ico" },
  callback = function(ev)
    vim.system({ "qlmanage", "-p", vim.fn.fnamemodify(ev.file, ":p") }, { stdout = false, stderr = false })
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        pcall(vim.cmd, "bprevious")
        pcall(vim.api.nvim_buf_delete, ev.buf, { force = true })
      end
    end)
  end,
})

-- Claude Code en un split de terminal (<leader>c)
map("n", "<leader>c", "<cmd>vsplit | terminal claude<cr>", "Claude Code")
