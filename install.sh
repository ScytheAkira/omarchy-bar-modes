#!/bin/bash
# Omarchy bar modes: patch your clone of Omarchy's bar plugin.
#
#   ./install.sh            install (clones omarchy.bar first if you have no clone)
#   ./install.sh --force    install on an Omarchy version it has not been tested on
#   ./install.sh --undo     put back the Bar.qml this replaced (or the stock one)
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
PLUGINS="$HOME/.config/omarchy/plugins"
BACKUPS="$HOME/.config/omarchy/theme-backups"
TESTED="omarchy 4.0.6-1"

bar_dir() {
  local m
  for m in "$PLUGINS"/*/manifest.json; do
    [[ -f $m ]] && grep -q '"clonedFrom": *"omarchy.bar"' "$m" && { dirname "$m"; return; }
  done
  return 0
}

if [[ ${1:-} == --undo ]]; then
  dir="$(bar_dir)"; [[ -n $dir ]] || { echo "no bar clone found"; exit 0; }
  last="$(ls -d "$BACKUPS/$(basename "$dir")".* 2>/dev/null | sort | head -1 || true)"
  if [[ -n $last ]]; then cp "$last/Bar.qml" "$dir/"; echo "restored $dir/Bar.qml from $last"
  else cp /usr/share/omarchy/shell/plugins/bar/Bar.qml "$dir/"; echo "reset $dir/Bar.qml to stock"; fi
  omarchy restart shell >/dev/null 2>&1 || true
  exit 0
fi

have="$(pacman -Q omarchy 2>/dev/null || true)"
if [[ " $TESTED " != *" $have "* && ${1:-} != --force ]]; then
  echo "Bar.qml is tested on '$TESTED'; you have '${have:-unknown}'." >&2
  echo "A bar plugin that fails to load leaves you without a bar. Compare Bar.qml with" >&2
  echo "/usr/share/omarchy/shell/plugins/bar/Bar.qml, then rerun with --force." >&2
  exit 1
fi

dir="$(bar_dir)"
if [[ -z $dir ]]; then
  omarchy plugin clone omarchy.bar
  dir="$(bar_dir)"
fi
[[ -n $dir ]] || { echo "could not find or create a clone of omarchy.bar" >&2; exit 1; }

backup="$BACKUPS/$(basename "$dir").$(date +%s)"
mkdir -p "$backup"
cp -a "$dir/." "$backup/"
cp "$SRC/Bar.qml" "$dir/"
echo "patched $dir (backup: $backup)"
omarchy restart shell >/dev/null 2>&1 || true
echo "Done. Double-click, middle-click or right-click empty bar space."
