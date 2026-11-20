# dotfiles

Mi configuración de terminal para desarrollar en Flutter: Neovim, Ranger y Warp, con el tema [Gruvbox Flutter](https://github.com/Stratovarius93/gruvbox-flutter-theme).

| Carpeta | Destino | Cómo se instala |
|---|---|---|
| `nvim/` | `~/.config/nvim` | enlace simbólico |
| `ranger/` | `~/.config/ranger` | enlace simbólico |
| `warp/` | `~/.warp` | copia (Warp reescribe `settings.toml`) |

## Instalación

```sh
git clone https://github.com/Stratovarius93/dotfiles ~/Developer/dotfiles
brew install neovim ranger chafa ripgrep
~/Developer/dotfiles/install.sh
nvim   # lazy.nvim instala los plugins al abrir
```

Si ya tienes una config de nvim o ranger, `install.sh` la guarda como `*.backup-<fecha>` antes de enlazar.

## Fuente con iconos

Warp no busca en otra fuente los iconos que faltan en la principal, así que la fuente tiene que traerlos dentro. Uso Cartograph CF con los iconos de Nerd Fonts añadidos. Cartograph es de pago y **no está en este repo**: cada uno tiene que crear su propia copia.

```sh
brew install fontforge
curl -sSLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FontPatcher.zip
unzip FontPatcher.zip -d FontPatcher && cd FontPatcher
for f in Regular RegularItalic Bold BoldItalic; do
  fontforge -script font-patcher --complete --careful -out out ~/Library/Fonts/CartographCF-$f.otf
done
cp out/*.otf ~/Library/Fonts/
```

Esto crea la familia **CartographCF Nerd Font**, que es la que usa `warp/settings.toml`. Sin Cartograph sirve cualquier Nerd Font (por ejemplo, JetBrainsMono Nerd Font): cambia `font_name` en `warp/settings.toml`. Si no quieres iconos, pon `vim.g.have_nerd_font = false` al principio de `nvim/init.lua`.

## Neovim

`<leader>` es la barra espaciadora.

### Plugins

- **Tema:** gruvbox-flutter
- **Flutter y Dart:** flutter-tools (con fvm), LSP de Dart, nvim-treesitter
- **Autocompletado:** nvim-cmp, LuaSnip, friendly-snippets
- **Archivos:** nvim-tree (árbol lateral), mini.files (columnas), Ranger (ventana flotante), Telescope (búsqueda)
- **Interfaz:** bufferline (tabs), gitsigns, neoscroll (scroll suave), flash, toggleterm
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
| `Tab` / `` ` `` | Tab siguiente / anterior |
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
