#!/bin/zsh
# Enlaza nvim y ranger a este repo y copia la config de Warp.
# Si ya existe una config que no es enlace, la guarda como *.backup-<fecha>.
set -e
DOTFILES="${0:A:h}"
STAMP=$(date +%Y%m%d-%H%M%S)

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

echo
echo "Dependencias (si faltan): brew install neovim ranger chafa ripgrep fontforge"
echo "Abre nvim: lazy.nvim instala los plugins solo."
