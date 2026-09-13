# Sourced by demo.tape before recording. Not part of the install.
source "${0:A:h}/../preview.zsh"
# Preview.app can't show up in a terminal GIF, so stand in for `open` and say what it would do.
open() { print -P -- "%F{242}→ Preview.app: ${@[-1]:t}%f"; }
PREVIEW_PAGER=cat
PROMPT='%F{blue}~/Downloads%f %F{green}❯%f '
RPROMPT=
touch photo.jpg notes.txt
clear
