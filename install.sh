#!/bin/zsh
# Deja la terminal lista en una Mac nueva:
#   1. Homebrew y todo lo del Brewfile (nvim, ranger, chafa, ripgrep, fvm, fuente con iconos…)
#   2. Warp, si no está instalado
#   3. Enlaces de nvim y ranger a este repo, y copia de la config de Warp
#   4. Fuente: Cartograph CF con iconos si tienes Cartograph; si no, JetBrainsMono Nerd Font
#   5. Plugins de nvim (versiones de lazy-lock.json) y parsers de Treesitter
#   6. Antigravity IDE (si está instalado): settings, atajos, extensiones y tema Gruvbox Flutter
# Se puede ejecutar varias veces: lo que ya está hecho se salta.
set -e
DOTFILES="${0:A:h}"
STAMP=$(date +%Y%m%d-%H%M%S)
FONTS="$HOME/Library/Fonts"
step() { print -P "\n%F{yellow}==>%f %B$1%b" }

# ── 1. Homebrew y paquetes ────────────────────────────────
step "Homebrew"
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
xcode-select -p >/dev/null 2>&1 || xcode-select --install || true   # compilador para Treesitter
brew bundle --file="$DOTFILES/Brewfile"

# ── 2. Warp ───────────────────────────────────────────────
step "Warp"
if [[ -d /Applications/Warp.app ]]; then
  echo "Ya instalado"
else
  brew install --cask warp
fi

# ── 3. Enlaces y config ───────────────────────────────────
step "Config de nvim, ranger y Warp"
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

# Warp reescribe settings.toml, así que se copia en lugar de enlazarse
mkdir -p "$HOME/.warp/themes"
[[ -f "$HOME/.warp/settings.toml" ]] && cp "$HOME/.warp/settings.toml" "$HOME/.warp/settings.toml.backup-$STAMP"
cp "$DOTFILES/warp/settings.toml" "$HOME/.warp/settings.toml"
cp "$DOTFILES/warp/themes/"*.yaml "$HOME/.warp/themes/"
echo "Copiado: config y tema de Warp"

# ── 4. Fuente con iconos ──────────────────────────────────
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
sed -i '' -E "s/^(ai_)?font_name = \".*\"/\1font_name = \"$FONT\"/" "$HOME/.warp/settings.toml"
echo "Warp usará: $FONT"

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

print -P "\n%F{green}Todo listo.%f Abre Warp (o reinícialo con Cmd+Q) y ejecuta: nvim"
[[ "$FONT" == "JetBrainsMono Nerd Font" ]] && echo "¿Tienes Cartograph CF? Instálala en ~/Library/Fonts y vuelve a ejecutar install.sh para usarla con iconos."
command -v flutter >/dev/null || echo "Flutter no está instalado: fvm install stable && fvm global stable"
true
