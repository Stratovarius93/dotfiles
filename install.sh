#!/bin/zsh
# Deja la terminal lista en una Mac nueva:
#   0. Pregunta a qué terminal aplicar los cambios (Warp, Terminal de macOS, Ghostty o todas)
#   1. Homebrew y todo lo del Brewfile (nvim, ranger, chafa, ripgrep, fvm, starship, fzf, carapace…)
#   2. Warp y/o Ghostty, si se eligieron y no están instalados
#   3. Oh My Zsh + fzf-tab, enlaces de nvim, ranger, starship y zsh, y copia de la config de Warp
#   4. Fuente: Cartograph CF con iconos si tienes Cartograph; si no, JetBrainsMono Nerd Font
#      + perfil Gruvbox Flutter en Terminal de macOS y config de Ghostty (si se eligieron)
#   5. Plugins de nvim (versiones de lazy-lock.json) y parsers de Treesitter
#   6. Antigravity IDE (si está instalado): settings, atajos, extensiones y tema Gruvbox Flutter
# Se puede ejecutar varias veces: lo que ya está hecho se salta.
# Uso opcional sin preguntar: ./install.sh [--warp] [--terminal] [--ghostty] [--all]
set -e
DOTFILES="${0:A:h}"
STAMP=$(date +%Y%m%d-%H%M%S)
FONTS="$HOME/Library/Fonts"
step() { print -P "\n%F{yellow}==>%f %B$1%b" }

# ── 0. Selección de terminal ──────────────────────────────
APPLY_WARP=false
APPLY_TERMINAL=false
APPLY_GHOSTTY=false
SELECTED_ANY=false

for arg in "$@"; do
  case "$arg" in
    --warp)     APPLY_WARP=true; SELECTED_ANY=true ;;
    --terminal) APPLY_TERMINAL=true; SELECTED_ANY=true ;;
    --ghostty)  APPLY_GHOSTTY=true; SELECTED_ANY=true ;;
    --all)      APPLY_WARP=true; APPLY_TERMINAL=true; APPLY_GHOSTTY=true; SELECTED_ANY=true ;;
    -h|--help)
      echo "Uso: $0 [--warp] [--terminal] [--ghostty] [--all]"
      exit 0
      ;;
  esac
done

if ! $SELECTED_ANY; then
  if [[ -t 0 ]]; then
    step "Terminal"
    echo "¿A qué terminal quieres aplicar la configuración y los colores?"
    echo "  1) Warp"
    echo "  2) Terminal de macOS"
    echo "  3) Ghostty"
    echo "  4) Todas (Warp, Terminal de macOS y Ghostty) [por defecto]"
    while true; do
      read -r "choice?Elige una opción (o varias separadas por coma, ej. 2,3) [1-4]: "
      choice="${choice// /}"
      if [[ -z "$choice" ]]; then
        APPLY_WARP=true; APPLY_TERMINAL=true; APPLY_GHOSTTY=true; break
      fi
      APPLY_WARP=false; APPLY_TERMINAL=false; APPLY_GHOSTTY=false
      valid=true
      for item in ${(s:,:)choice:l}; do
        case "$item" in
          1|warp)               APPLY_WARP=true ;;
          2|terminal|macos)     APPLY_TERMINAL=true ;;
          3|ghostty)            APPLY_GHOSTTY=true ;;
          4|todas|todos|all)    APPLY_WARP=true; APPLY_TERMINAL=true; APPLY_GHOSTTY=true ;;
          *)                    valid=false ;;
        esac
      done
      if $valid && ( $APPLY_WARP || $APPLY_TERMINAL || $APPLY_GHOSTTY ); then
        break
      fi
      echo "Opción no válida. Escribe 1, 2, 3, 4 o varias separadas por coma (ej. 2,3)."
    done
  else
    APPLY_WARP=true; APPLY_TERMINAL=true; APPLY_GHOSTTY=true
  fi
fi

# ── 1. Homebrew y paquetes ────────────────────────────────
step "Homebrew"
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
xcode-select -p >/dev/null 2>&1 || xcode-select --install || true   # compilador para Treesitter
brew bundle --file="$DOTFILES/Brewfile"

# gitree (TUI de commits estilo GitKraken): no es fatal si falta go o aún no está publicado
if command -v go >/dev/null; then
  go install github.com/Stratovarius93/gitree@latest \
    || echo "Aviso: no se pudo instalar gitree (¿módulo aún no publicado?); sigo sin él"
else
  echo "Aviso: go no está instalado; omito gitree"
fi

# ── 2. Warp / Ghostty ─────────────────────────────────────
if $APPLY_WARP; then
  step "Warp"
  if [[ -d /Applications/Warp.app ]]; then
    echo "Ya instalado"
  else
    brew install --cask warp
  fi
fi

if $APPLY_GHOSTTY; then
  step "Ghostty"
  if [[ -d /Applications/Ghostty.app ]]; then
    echo "Ya instalado"
  else
    brew install --cask ghostty
  fi
fi

# ── 3. Oh My Zsh, enlaces y config ────────────────────────
step "Oh My Zsh, Starship y config"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
FZF_TAB_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab"
if [[ ! -d "$FZF_TAB_DIR" ]]; then
  git clone -q --depth 1 https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR"
  echo "Instalado: fzf-tab"
fi

link() {
  local src="$1" dst="$2"
  mkdir -p "${dst:h}"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    mv "$dst" "$dst.backup-$STAMP"
    echo "Respaldo: $dst.backup-$STAMP"
  fi
  ln -s "$src" "$dst"
  echo "Enlazado: $dst -> $src"
}
link "$DOTFILES/nvim" "$HOME/.config/nvim"
link "$DOTFILES/ranger" "$HOME/.config/ranger"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
link "$DOTFILES/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"

if $APPLY_WARP; then
  # Warp reescribe settings.toml, así que se copia en lugar de enlazarse
  mkdir -p "$HOME/.warp/themes"
  [[ -f "$HOME/.warp/settings.toml" ]] && cp "$HOME/.warp/settings.toml" "$HOME/.warp/settings.toml.backup-$STAMP"
  cp "$DOTFILES/warp/settings.toml" "$HOME/.warp/settings.toml"
  cp "$DOTFILES/warp/themes/"*.yaml "$HOME/.warp/themes/"
  echo "Copiado: config y tema de Warp"
fi

# ── 4. Fuente con iconos y colores de terminal ────────────
step "Fuente"
patch_cartograph() {
  local tmp; tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/fp.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FontPatcher.zip
  unzip -q "$tmp/fp.zip" -d "$tmp/patcher"
  for f in Regular RegularItalic Bold BoldItalic; do
    [[ -f "$FONTS/CartographCF-$f.otf" ]] || continue
    echo "Añadiendo iconos a CartographCF-$f…"
    (cd "$tmp/patcher" && fontforge -script font-patcher --complete --careful -out "$tmp/out" "$FONTS/CartographCF-$f.otf" >/dev/null 2>&1)
  done
  cp "$tmp/out/"*.otf "$FONTS/"
  rm -rf "$tmp"
}
if [[ -f "$FONTS/CartographCFNerdFont-Regular.otf" ]]; then
  FONT="CartographCF Nerd Font"
elif [[ -f "$FONTS/CartographCF-Regular.otf" ]]; then
  patch_cartograph
  FONT="CartographCF Nerd Font"
else
  FONT="JetBrainsMono Nerd Font"
fi

echo "Fuente detectada: $FONT"
if $APPLY_WARP; then
  sed -i '' -E "s/^(ai_)?font_name = \".*\"/\1font_name = \"$FONT\"/" "$HOME/.warp/settings.toml"
  echo "Warp usará: $FONT"
fi

apply_macos_terminal() {
  local src_profile="$1" font_ps="$2"
  local tmp; tmp=$(mktemp -d)
  local tmp_profile="$tmp/Gruvbox Flutter.terminal"

  python3 - "$src_profile" "$tmp_profile" "$font_ps" <<'PY'
import plistlib, subprocess, sys

src_path, out_path, font_ps = sys.argv[1:4]
with open(src_path, "rb") as f:
    profile = plistlib.load(f)

profile_name = profile.get("name", "Gruvbox Flutter")
if "Font" in profile:
    font_archive = plistlib.loads(profile["Font"])
    objs = font_archive.get("$objects", [])
    for obj in objs:
        if isinstance(obj, dict) and "NSName" in obj and isinstance(obj["NSName"], plistlib.UID):
            objs[obj["NSName"].data] = font_ps
            break
    profile["Font"] = plistlib.dumps(font_archive, fmt=plistlib.FMT_BINARY)

with open(out_path, "wb") as f:
    plistlib.dump(profile, f, fmt=plistlib.FMT_XML, sort_keys=True)

exported = subprocess.run(
    ["defaults", "export", "com.apple.Terminal", "-"],
    capture_output=True,
)
prefs = plistlib.loads(exported.stdout) if exported.stdout.strip() else {}
ws = prefs.setdefault("Window Settings", {})
ws[profile_name] = profile
prefs["Default Window Settings"] = profile_name
prefs["Startup Window Settings"] = profile_name
subprocess.run(
    ["defaults", "import", "com.apple.Terminal", "-"],
    input=plistlib.dumps(prefs, fmt=plistlib.FMT_XML),
    check=True,
)
PY

  if pgrep -xq Terminal 2>/dev/null; then
    osascript - "$tmp_profile" <<'APPLESCRIPT' >/dev/null 2>&1 || echo "  (Reinicia Terminal.app para aplicar el perfil a las ventanas abiertas)"
on run argv
  set profilePath to POSIX file (item 1 of argv)
  tell application "Terminal"
    set existingIds to id of windows
    open profilePath
    repeat 15 times
      if "Gruvbox Flutter" is in (name of settings sets) then exit repeat
      delay 0.2
    end repeat
    set targetSettings to settings set "Gruvbox Flutter"
    set default settings to targetSettings
    set startup settings to targetSettings
    set allIds to id of windows
    repeat with wid in allIds
      if wid is in existingIds then
        repeat with t in tabs of (window id wid)
          set current settings of t to targetSettings
        end repeat
      else
        close (window id wid) saving no
      end if
    end repeat
  end tell
end run
APPLESCRIPT
  fi

  rm -rf "$tmp"
  echo "Terminal de macOS: perfil 'Gruvbox Flutter' aplicado ($font_ps)"
}

if $APPLY_TERMINAL; then
  step "Terminal de macOS"
  if [[ -f "$FONTS/CartographCFNerdFontMono-Regular.otf" ]]; then
    TERMINAL_FONT_PS="CartographCFNFM"
  elif [[ -f "$FONTS/CartographCFNerdFont-Regular.otf" ]]; then
    TERMINAL_FONT_PS="CartographCFNF"
  else
    TERMINAL_FONT_PS="JetBrainsMonoNF-Regular"
  fi
  apply_macos_terminal "$DOTFILES/terminal/Gruvbox Flutter.terminal" "$TERMINAL_FONT_PS"
fi

apply_ghostty() {
  local src_cfg="$1" font_family="$2"
  local dst_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
  local dst_cfg="$dst_dir/config.ghostty"
  local ghostty_bin="/Applications/Ghostty.app/Contents/MacOS/ghostty"
  local tmp; tmp=$(mktemp)

  sed -E "s/^font-family = .*/font-family = $font_family/" "$src_cfg" > "$tmp"
  mkdir -p "$dst_dir"
  if [[ -f "$dst_cfg" ]] && ! cmp -s "$tmp" "$dst_cfg"; then
    cp "$dst_cfg" "$dst_cfg.backup-$STAMP"
    echo "Respaldo: $dst_cfg.backup-$STAMP"
  fi
  cp "$tmp" "$dst_cfg"
  rm -f "$tmp"

  [[ -x "$ghostty_bin" ]] && "$ghostty_bin" +validate-config >/dev/null 2>&1 || true
  if pgrep -xq ghostty 2>/dev/null; then
    osascript -e 'tell application "Ghostty" to perform action "reload_config" on terminal 1' >/dev/null 2>&1 \
      || echo "  (Pulsa Cmd+Shift+, en Ghostty para recargar la configuración)"
  fi
  echo "Ghostty: config y tema Gruvbox Flutter aplicados ($font_family)"
}

if $APPLY_GHOSTTY; then
  step "Ghostty"
  if [[ -f "$FONTS/CartographCFNerdFontMono-Regular.otf" ]]; then
    GHOSTTY_FONT="CartographCF Nerd Font Mono"
  elif [[ -f "$FONTS/CartographCFNerdFont-Regular.otf" ]]; then
    GHOSTTY_FONT="CartographCF Nerd Font"
  else
    GHOSTTY_FONT="JetBrainsMono Nerd Font"
  fi
  apply_ghostty "$DOTFILES/ghostty/config.ghostty" "$GHOSTTY_FONT"
fi

# ── 5. Plugins de nvim ────────────────────────────────────
step "Plugins de nvim (puede tardar un par de minutos)"
nvim --headless "+Lazy! restore" +qa
nvim --headless "+TSUpdateSync" +qa
echo "Listo"

# ── 6. Antigravity IDE ────────────────────────────────────
step "Antigravity IDE"
AG_APP="/Applications/Antigravity IDE.app"
AG_CLI="$AG_APP/Contents/Resources/app/bin/antigravity-ide"
AG_USER="$HOME/Library/Application Support/Antigravity IDE/User"
if [[ -x "$AG_CLI" ]]; then
  mkdir -p "$AG_USER"
  for f in settings.json keybindings.json; do
    if [[ -f "$AG_USER/$f" ]] && ! cmp -s "$DOTFILES/antigravity/$f" "$AG_USER/$f"; then
      cp "$AG_USER/$f" "$AG_USER/$f.backup-$STAMP"
      echo "Respaldo: $AG_USER/$f.backup-$STAMP"
    fi
    cp "$DOTFILES/antigravity/$f" "$AG_USER/$f"
  done
  echo "Copiado: settings.json y keybindings.json"
  installed=$("$AG_CLI" --list-extensions 2>/dev/null)
  while read -r ext; do
    [[ -z "$ext" ]] && continue
    if print -r -- "$installed" | grep -qix "$ext"; then
      echo "Extensión ya instalada: $ext"
    else
      "$AG_CLI" --install-extension "$ext" >/dev/null 2>&1 && echo "Instalada: $ext" || echo "No se pudo instalar: $ext"
    fi
  done < "$DOTFILES/antigravity/extensions.txt"
  # El tema Gruvbox Flutter no está en el marketplace: se empaqueta desde su repo
  if print -r -- "$installed" | grep -qix "stratovarius93.gruvbox-flutter-theme"; then
    echo "Extensión ya instalada: stratovarius93.gruvbox-flutter-theme"
  else
    tmp=$(mktemp -d)
    git clone -q --depth 1 https://github.com/Stratovarius93/gruvbox-flutter-theme "$tmp/theme"
    (cd "$tmp/theme" && npx --yes @vscode/vsce package -o "$tmp/theme.vsix" >/dev/null 2>&1) \
      && "$AG_CLI" --install-extension "$tmp/theme.vsix" >/dev/null 2>&1 && echo "Instalada: Gruvbox Flutter Theme" \
      || echo "No se pudo instalar el tema Gruvbox Flutter (ver README)"
    rm -rf "$tmp"
  fi
else
  echo "Antigravity IDE no está instalado: instálalo y vuelve a ejecutar install.sh para copiar su config"
fi

terminals=()
$APPLY_WARP && terminals+=("Warp")
$APPLY_TERMINAL && terminals+=("Terminal.app")
$APPLY_GHOSTTY && terminals+=("Ghostty")
print -P "\n%F{green}Todo listo.%f Terminales configuradas: ${(j:, :)terminals}. Abre tu terminal y ejecuta: nvim"
[[ "$FONT" == "JetBrainsMono Nerd Font" ]] && echo "¿Tienes Cartograph CF? Instálala en ~/Library/Fonts y vuelve a ejecutar install.sh para usarla con iconos."
command -v flutter >/dev/null || echo "Flutter no está instalado: fvm install stable && fvm global stable"
true
