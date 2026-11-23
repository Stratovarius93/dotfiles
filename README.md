# dotfiles

Mi configuración para desarrollar en Flutter: Neovim, Ranger, Zsh + Starship, Warp, Terminal de macOS, Ghostty y Antigravity IDE, con el tema [Gruvbox Flutter](https://github.com/Stratovarius93/gruvbox-flutter-theme).

| Carpeta | Destino | Cómo se instala |
|---|---|---|
| `nvim/` | `~/.config/nvim` | enlace simbólico |
| `ranger/` | `~/.config/ranger` | enlace simbólico |
| `starship/` | `~/.config/starship.toml` | enlace simbólico (prompt Gruvbox en dos líneas con emojis y hora) |
| `zsh/` | `~/.zshrc` | enlace simbólico (Oh My Zsh + `fzf-tab`, `carapace`, `zsh-autosuggestions`, `zsh-syntax-highlighting` y Starship) |
| `warp/` | `~/.warp` | copia (Warp reescribe `settings.toml`) |
| `terminal/` | `Terminal.app` (`Gruvbox Flutter`) | importa el perfil `.terminal` como predeterminado y de inicio |
| `ghostty/` | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` | copia con la fuente detectada, colores Gruvbox Flutter y ventana `148×46` |
| `antigravity/` | `~/Library/Application Support/Antigravity IDE/User` | copia de `settings.json` y `keybindings.json`, y extensiones de `extensions.txt` |

## Instalación en una Mac nueva

1. **(Opcional) Instala Cartograph CF** en `~/Library/Fonts` si la tienes (ver [Fuentes](#fuentes)).
2. Ejecuta:

   ```sh
   git clone https://github.com/Stratovarius93/dotfiles ~/Developer/dotfiles
   ~/Developer/dotfiles/install.sh
   ```

3. Elige a qué terminal aplicar la configuración y los colores (**Warp**, **Terminal de macOS**, **Ghostty** o **Todas**; también puedes elegir varias separadas por coma, ej. `2,3`). También puedes pasarlo directo con `--warp`, `--terminal`, `--ghostty` o `--all`.
4. Abre tu terminal (si usas Warp, reinícialo con Cmd+Q) y escribe `nvim`.

`install.sh` hace todo lo demás:

- Pregunta a qué terminal aplicar los cambios (`Warp`, `Terminal de macOS`, `Ghostty`, una combinación o todas).
- Instala Homebrew, si no está, y todo lo del [`Brewfile`](Brewfile): neovim, ranger, lazygit, chafa, bat, ripgrep, fd, fvm, node, starship, fzf, carapace, zsh-autosuggestions, zsh-syntax-highlighting, fontforge y JetBrainsMono Nerd Font.
- Instala Oh My Zsh y el plugin `fzf-tab` si aún no están.
- Instala Warp y/o Ghostty si los elegiste y aún no están.
- Enlaza `~/.config/nvim`, `~/.config/ranger`, `~/.config/starship.toml` y `~/.zshrc` a este repo (puedes añadir ajustes locales por máquina en `~/.zshrc.local`), copia la config y el tema de Warp (si se eligió), importa el perfil [`terminal/Gruvbox Flutter.terminal`](terminal/Gruvbox%20Flutter.terminal) en la app Terminal de macOS (si se eligió), y copia [`ghostty/config.ghostty`](ghostty/config.ghostty) en Ghostty con recarga en vivo (si se eligió). Si ya había una config, la guarda como `*.backup-<fecha>`.
- Elige la fuente:
  - **CartographCF Nerd Font**, si ya tienes Cartograph con iconos.
  - Si tienes Cartograph sin iconos, se los añade automáticamente y usa esa.
  - **JetBrainsMono Nerd Font** en cualquier otro caso.
- Instala los plugins de nvim con las versiones exactas de `lazy-lock.json` y los parsers de Treesitter.
- Si Antigravity IDE está instalado, copia su `settings.json` y `keybindings.json` (guardando un `*.backup-<fecha>` si eran distintos), instala las extensiones de [`antigravity/extensions.txt`](antigravity/extensions.txt) y empaqueta e instala el tema [Gruvbox Flutter](https://github.com/Stratovarius93/gruvbox-flutter-theme) desde su repo, porque no está en el marketplace. Si Antigravity no está instalado, se salta este paso: instálalo y vuelve a ejecutar `install.sh`.

Se puede volver a ejecutar sin problema: lo que ya está hecho se salta. Si instalas Cartograph después, vuelve a ejecutarlo para usarla.

Lo que **no** se guarda en este repo: Flutter, Xcode, Android Studio, Cartograph CF y Claude Code (se instalan aparte), y los datos que nvim genera con el uso (archivos recientes, caché de dispositivos), que se vuelven a crear solos.

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
- **Interfaz:** tabs por panel tipo píldora ([`lua/wintabs.lua`](nvim/lua/wintabs.lua)), animaciones de paneles al abrir/cerrar nvim-tree, terminal y trouble ([`lua/anim.lua`](nvim/lua/anim.lua)), barra lateral nvim-tree + Flutter Outline ([`lua/sidebar.lua`](nvim/lua/sidebar.lua)), bordes redondeados en ventanas flotantes, lualine (barra de estado estilo burbujas), trouble (panel de problemas), gitsigns, neoscroll (scroll suave), flash, toggleterm
- **Colores:** nvim-highlight-colors (`#RRGGBB`, `rgb()`, `hsl()`) y resaltador propio para `0xAARRGGBB` de Flutter
- **Tests:** nvim-coverage

### Funciones automáticas

- **Reabrir archivos:** `nvim` o `nvim .` vuelve a abrir los archivos de la última vez en esa carpeta, con la posición del cursor. Si sales 3 veces seguidas con los mismos archivos, la siguiente vez arranca limpio. `nvim archivo.dart` abre solo ese archivo.
- **Estilo Error Lens:** las líneas con errores o warnings se pintan de rojo o amarillo, con el mensaje al final.
- **Colores visibles:** los códigos de color (`#ea6962`, `rgb(…)`, `0xffa2a2a2`) se muestran con su color de fondo. En Dart, `Colors.x` y `Color(0x…)` los pinta el LSP.
- **Tabs por panel:** cada panel tiene su propia fila de tabs, como los grupos de editor de VS Code. Se puede hacer clic en una tab, y clic con la rueda la cierra.

### Atajos

**Archivos y búsqueda**

| Atajo | Acción |
|---|---|
| `<leader>n` / `<leader>e` | Mostrar u ocultar la barra lateral (árbol + Flutter Outline debajo en archivos Dart) / ir al árbol |
| `-` | mini.files (columnas tipo Ranger, editables) |
| `<leader>o` | Ranger flotante |
| `<leader>f` | Buscar archivo; los recientes del proyecto salen primero, marcados con 󰋚 |
| `<leader>F` | Buscar texto en todo el proyecto |
| `<leader>/` | Paleta de comandos |
| `<leader>S` | Buscar y reemplazar **en el archivo actual** |
| `/` y luego `n` / `N` | Buscar en el archivo actual / siguiente / anterior |
| `Ctrl+n` | Quitar el resaltado de la búsqueda |

En Telescope: `Ctrl+j` / `Ctrl+k` mueven, `Enter` abre, `Ctrl+Enter` (o `Ctrl+v`) abre en un panel a la derecha y `Ctrl+q` manda los resultados a la lista quickfix.

En el árbol: `Enter` u `o` abre, `s` o `Shift+Enter` abre a la derecha, `i` abre debajo, `u` sube un nivel, `I` muestra los ocultos y `?` muestra la ayuda.

**Imágenes**

| Atajo | Acción |
|---|---|
| `Espacio` (sola, sobre una ruta como `'assets/img/x.png'`) | Vista previa flotante junto al cursor; `Espacio` otra vez, `q`, `Esc` o mover el cursor la cierra |
| `<leader>P` | Abrir la imagen en Vista Rápida de macOS (tamaño real) |

Busca también las variantes `2.0x/` y `3.0x/` de Flutter. La vista flotante usa chafa (caracteres de color), porque Warp no muestra imágenes reales dentro de nvim.

**Tabs y paneles**

| Atajo | Acción |
|---|---|
| `Tab` / `` ` `` | Tab siguiente / anterior del panel |
| `<leader>1`…`9` | Ir a la tab N del panel (menos `6`) |
| `<leader><` / `<leader>>` | Mover la tab a la izquierda / derecha |
| `<leader>bo` | Cerrar las demás tabs del panel |
| `<leader>bp` | Elegir entre todos los archivos abiertos |
| `q` (o `<leader>q`) | Cerrar la tab; si era la última del panel, se cierra el panel. En logs, outline o ayuda, cierra el panel |
| `Q` | Cerrar todo y salir (pregunta si hay cambios sin guardar) |
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
| `F4` / `Shift+F4` | Problemas de todo el proyecto / del archivo (trouble) |

**Edición**

| Atajo | Acción |
|---|---|
| `jk` o `kj` | Salir de INSERT |
| `<leader>,` / `<leader>;` | Poner `,` / `;` al final de la línea |
| `<leader>6` / `<leader>^` | Seleccionar el bloque desde el inicio de la línea / desde la palabra |
| `<leader>s` | Saltar a cualquier parte de la pantalla (flash) |

**Flutter**

| Atajo | Acción |
|---|---|
| `F5` | Menú de Flutter (ver abajo) |
| `<leader>d` | `flutter run` directo |
| `F6` o `<leader>r` / `F7` o `<leader>R` | Hot reload / hot restart |
| `F8` | Detener la app |
| `F3` | Logs de la app (como la Debug Console) |
| `F2` | Salida: historial de mensajes de nvim (como Output) |
| `<leader>N` | Mostrar u ocultar el Flutter Outline (árbol de widgets) debajo del árbol de archivos |
| `<leader>tc` | Tests con cobertura |
| `<leader>tl` / `<leader>tt` / `<leader>ts` | Cargar / mostrar u ocultar / resumen de la cobertura |

**Menú `F5`** ([`lua/flutter_menu.lua`](nvim/lua/flutter_menu.lua)):

- **Con la app detenida** muestra los dispositivos (físicos, simuladores, escritorio, Chrome) y los emuladores apagados para iniciarlos. Abre al instante con los de la última búsqueda y se actualiza solo cuando termina `flutter devices`.
- Al elegir un dispositivo pide el **entorno**:
  - Si el proyecto tiene `.vscode/launch.json`, usa sus configuraciones (`--flavor`, `program` como `--target`, `flutterMode`, `args` y `toolArgs`).
  - Si no, detecta los flavors de `android/app/build.gradle(.kts)` y de los esquemas de Xcode, solo los de la plataforma del dispositivo, y usa `lib/**/main_<flavor>.dart` como target si existe.
  - El último entorno usado sale primero. Si hay uno solo, no pregunta.
- **Con la app corriendo** muestra Hot Reload, Hot Restart, Stop, DevTools en el navegador, Copiar URL del profiler, Logs, Inspeccionar widget, Debug paint, Performance overlay, Repaint rainbow, Animaciones lentas, Brillo y Desconectar.

**Otros**

| Atajo | Acción |
|---|---|
| `F1` | Terminal |
| `<leader>c` | Mostrar / ocultar Claude Code a la derecha. Al ocultarlo sigue corriendo y vuelve la misma sesión |
| `Ctrl+q` (dentro de Claude) | Ocultar Claude Code |
| `Ctrl+h` / `Ctrl+l` (dentro de Claude) | Ir al panel de la izquierda / derecha (al volver se sigue escribiendo) |
| `Ctrl+\` `Ctrl+n` (dentro de una terminal) | Pasar a modo normal, por ejemplo para copiar texto |

Al salir de Claude (`/exit`) su panel se cierra solo.

## Antigravity IDE

[`antigravity/`](antigravity/) guarda `settings.json` (VSCodeVim con los mismos atajos que nvim, tema e iconos Gruvbox Flutter, fuente Cartograph CF), `keybindings.json` y la lista de extensiones. `install.sh` los copia e instala.

Si cambias la config en Antigravity, actualiza el repo con:

```sh
U="$HOME/Library/Application Support/Antigravity IDE/User"
cp "$U/settings.json" "$U/keybindings.json" ~/Developer/dotfiles/antigravity/
"/Applications/Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide" --list-extensions \
  | grep -v '^stratovarius93.gruvbox-flutter-theme$' > ~/Developer/dotfiles/antigravity/extensions.txt
```

## Ranger

- **Vista previa en la misma terminal** ([`ranger/scope.sh`](ranger/scope.sh) y [`ranger/rc.conf`](ranger/rc.conf)): código, JSON, Markdown y archivos de texto se muestran con resaltado **Gruvbox Dark** (`bat`), e imágenes con [chafa](https://hpjansson.org/chafa/) como caracteres de color (funciona también dentro de nvim).
- **`i`**: vista previa a pantalla completa del archivo en la misma terminal (`q` o `Esc` vuelven a Ranger).
- **`Enter` / `l`**: abre archivos de texto/código en `nvim` dentro de la misma terminal.
- **`q` / `Q`**: cierra Ranger y cambia la terminal (`cd`) a la carpeta donde estabas.
- **`Esc`**: cierra Ranger inmediatamente sin cambiar de carpeta.

## Zsh y Starship

- **Prompt ([`starship/starship.toml`](starship/starship.toml))**: diseño Gruvbox Flutter en dos líneas (`╭─` / `╰─❯`) con emojis (`📂`, `🌿`, `🎯`, `🟢`, `⏱️`) y hora (`🕐 HH:MM`) alineada a la derecha.
- **Autocompletado ([`zsh/zshrc`](zsh/zshrc))**: Oh My Zsh + `fzf-tab`, `carapace`, `zsh-autosuggestions` y `zsh-syntax-highlighting` con colores Gruvbox Flutter. Para configuración local por máquina sin tocar el repo, usa `~/.zshrc.local`.

| Atajo / Alias | Acción |
|---|---|
| `lg` | Abre `lazygit` |
| `rg` | Abre `ranger` (con `cd` al salir con `q`/`Q`; para `ripgrep` en shell usa `command rg`) |
| `Tab` | Menú desplegable interactivo (`fzf-tab` + descripciones de `carapace`) |
| `→` | Aceptar sugerencia en línea (`zsh-autosuggestions`) |
| `Ctrl+R` | Buscar en el historial con `fzf` |
| `Ctrl+T` | Buscar e insertar archivos con `fzf` |
| `Alt+C` | Cambiar de carpeta con `fzf` |
