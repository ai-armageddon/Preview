#!/bin/sh
# Install preview.zsh into ~/.local/share/preview and hook it into ~/.zshrc.
set -eu

SRC_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEST_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/preview"
DEST="$DEST_DIR/preview.zsh"
ZSHRC="$HOME/.zshrc"
MARKER='.local/share/preview/preview.zsh'

if [ ! -f "$SRC_DIR/preview.zsh" ]; then
  echo "install.sh: preview.zsh not found next to this script" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC_DIR/preview.zsh" "$DEST"
echo "installed  $DEST"

if [ ! -f "$ZSHRC" ]; then
  echo "note: no $ZSHRC found; add this line to your shell config:" >&2
  echo "  [ -f \"$DEST\" ] && source \"$DEST\"" >&2
  exit 0
fi

if grep -q "$MARKER" "$ZSHRC"; then
  echo "unchanged  $ZSHRC (source line already present)"
else
  printf '\n# Preview - open files in macOS Preview.app (https://github.com/ai-armageddon/Preview)\n[ -f "%s" ] && source "%s"\n' "$DEST" "$DEST" >> "$ZSHRC"
  echo "updated    $ZSHRC"
fi

echo
echo "Run 'source ~/.zshrc', then try: Preview --help"
