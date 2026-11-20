# dotfiles

Mi configuración de terminal para desarrollar en Flutter: Neovim, Ranger y Warp, con el tema [Gruvbox Flutter](https://github.com/Stratovarius93/gruvbox-flutter-theme).

| Carpeta | Destino | Cómo se instala |
|---|---|---|
| `nvim/` | `~/.config/nvim` | enlace simbólico |
| `ranger/` | `~/.config/ranger` | enlace simbólico |
| `warp/` | `~/.warp` | copia (Warp reescribe `settings.toml`) |

## Instalación en una Mac nueva

1. **(Opcional) Instala Cartograph CF** en `~/Library/Fonts` si la tienes (ver [Fuentes](#fuentes)).
2. Ejecuta:

   ```sh
   git clone https://github.com/Stratovarius93/dotfiles ~/Developer/dotfiles
   ~/Developer/dotfiles/install.sh
   ```

3. Abre Warp (o reinícialo con Cmd+Q) y escribe `nvim`.

`install.sh` hace todo lo demás:

- Instala Homebrew, si no está, y todo lo del [`Brewfile`](Brewfile): neovim, ranger, chafa, ripgrep, fd, fvm, fontforge y JetBrainsMono Nerd Font.
- Instala Warp si no está.
- Enlaza `~/.config/nvim` y `~/.config/ranger` a este repo, y copia la config y el tema de Warp. Si ya había una config, la guarda como `*.backup-<fecha>`.
- Elige la fuente:
  - **CartographCF Nerd Font**, si ya tienes Cartograph con iconos.
  - Si tienes Cartograph sin iconos, se los añade automáticamente y usa esa.
  - **JetBrainsMono Nerd Font** en cualquier otro caso.
- Instala los plugins de nvim con las versiones exactas de `lazy-lock.json` y los parsers de Treesitter.

Se puede volver a ejecutar sin problema: lo que ya está hecho se salta. Si instalas Cartograph después, vuelve a ejecutarlo para usarla.

Flutter no se instala solo, porque cada proyecto puede usar una versión distinta: `fvm install stable && fvm global stable`. Para `<leader>c` hace falta [Claude Code](https://claude.com/claude-code).

## Fuentes

La fuente **tiene que traer los iconos dentro (Nerd Font)**. Warp no busca en otra fuente los iconos que le faltan a la principal: sin una Nerd Font, el árbol, las tabs y Telescope salen con huecos en blanco.

| Fuente | Precio | Instalación |
|---|---|---|
| **Cartograph CF** (la que uso) | De pago | Cópiala a `~/Library/Fonts` antes de `install.sh` y le añade los iconos sola. Nunca se sube a este repo. |
| **JetBrainsMono Nerd Font** (por defecto) | Gratis | La instala `install.sh` |
| **Maple Mono NF** (cursivas a mano, parecida a Cartograph) | Gratis | `brew install --cask font-maple-mono-nf` |
| **CaskaydiaCove Nerd Font** (Cascadia Code) | Gratis | `brew install --cask font-caskaydia-cove-nerd-font` |

Para cambiar de fuente, pon su nombre en `font_name` y `ai_font_name` de `~/.warp/settings.toml` (o en Warp: Settings → Appearance) y reinicia Warp. Si no quieres iconos, pon `vim.g.have_nerd_font = false` al principio de `nvim/init.lua`.

## Neovim

`<leader>` es la barra espaciadora.

### Plugins

- **Tema:** gruvbox-flutter
- **Flutter y Dart:** flutter-tools (con fvm), LSP de Dart, nvim-treesitter
- **Autocompletado:** nvim-cmp, LuaSnip, friendly-snippets
- **Archivos:** nvim-tree (árbol lateral), mini.files (columnas), Ranger (ventana flotante), Telescope (búsqueda)
- **Interfaz:** tabs por panel (`lua/wintabs.lua`), lualine, trouble, gitsigns, neoscroll (scroll suave), flash, toggleterm
- **Tests:** nvim-coverage

### Atajos

**Archivos y búsqueda**

| Atajo | Acción |
|---|---|
| `<leader>n` / `<leader>e` | Mostrar u ocultar el árbol / ir al árbol |
| `-` | mini.files (columnas tipo Ranger, editables) |
| `<leader>o` | Ranger flotante |
| `<leader>f` / `<leader>F` | Buscar archivo / buscar texto |
| `<leader>/` | Paleta de comandos |
| `<leader>S` | Buscar y reemplazar |
| `<leader>p` | Ver la imagen con Vista Rápida de macOS |

En el árbol: `Enter` u `o` abre, `s` o `Shift+Enter` abre a la derecha, `i` abre debajo, `u` sube un nivel, `I` muestra los ocultos y `?` muestra la ayuda.

**Tabs y paneles**

| Atajo | Acción |
|---|---|
| `Tab` / `` ` `` | Tab siguiente / anterior del panel |
| `q` | Cerrar la tab, o el panel si la pantalla está dividida |
| `Q` | Cerrar todo y salir (pregunta si hay cambios sin guardar) |
| `<leader>bo` / `<leader>bp` | Cerrar las demás tabs / elegir tab por letra |
| `<leader><` / `<leader>>` | Mover la tab |
| `Ctrl+h/j/k/l` | Ir al panel de la izquierda / abajo / arriba / derecha |
| `<leader>w` / `<leader>W` | Guardar / guardar todo |
| `<leader>m` | Grabar macro (sustituye a `q`) |

**Código (LSP)**

| Atajo | Acción |
|---|---|
| `gd` / `<leader>gd` | Ir a la definición / abrirla a la derecha |
| `<leader>i` | Referencias |
| `<leader>x` | Documentación del símbolo |
| `<leader>a` | Arreglo rápido (quick fix) |
| `<leader>rn` | Renombrar |
| `Alt+j` / `Alt+k` | Error siguiente / anterior |

**Flutter**

| Atajo | Acción |
|---|---|
| `<leader>d` | `flutter run` |
| `<leader>r` o `F6` / `<leader>R` o `F7` | Hot reload / hot restart |
| `F8` / `F2` | Detener la app / ver los logs |
| `<leader>tc` | Tests con cobertura |
| `<leader>tl` / `<leader>tt` / `<leader>ts` | Cargar / mostrar u ocultar / resumen de la cobertura |

**Otros:** `jk` o `kj` salen de INSERT, `F1` abre la terminal y `<leader>c` abre Claude Code.

## Ranger

`ranger/scope.sh` es el script de vista previa que trae Ranger, con un cambio: las imágenes se muestran con [chafa](https://hpjansson.org/chafa/) como caracteres de color. Así se ven también dentro de nvim, donde Warp no puede mostrar imágenes reales.
