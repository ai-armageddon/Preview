# preview.zsh - open files in macOS Preview.app from the shell
#
#   Preview file.pdf ...   open each file in Preview
#   Preview                macOS file picker, opens whatever you select
#   Preview -f weird.xyz   skip the compatibility check
#   Preview -t doc.pdf     dump PDF text to the terminal (needs poppler)
#
# zsh resolves function names case-sensitively before falling through to PATH,
# so the capitalized `Preview` shadows the case-insensitive filesystem match
# for /System/Applications/Preview.app on APFS.
#
# https://github.com/ai-armageddon/Preview

PREVIEW_VERSION="1.1.0"

# Extensions Preview.app handles. Override or extend without editing this file:
#   PREVIEW_EXTRA_EXTS=(fits pcx)   in your zshrc, before sourcing
typeset -ga PREVIEW_EXTS
PREVIEW_EXTS=(
  # documents
  pdf ps eps epsf ai
  # common raster
  png jpg jpeg jpe gif tif tiff bmp ico icns
  # jpeg 2000
  jp2 jpf jpx j2k j2c
  # modern / apple
  heic heif hif avif webp
  # design / legacy
  psd svg tga exr hdr pict pct sgi
  # netpbm & friends
  pnm pbm pgm ppm xbm mpo
  # camera raw
  dng cr2 cr3 nef nrw arw srf sr2 raf orf rw2 srw pef ptx 3fr erf mos mrw dcr kdc x3f
)

# Dump the text layer of one or more PDFs to stdout. Internal; used by -t.
_preview_pdftotext() {
  emulate -L zsh
  local f multi=0
  local -a opts
  opts=(${=PREVIEW_PDFTOTEXT_OPTS:--layout})
  (( $# > 1 )) && multi=1

  for f in "$@"; do
    (( multi )) && print -r -- "==> ${f:t} <=="
    pdftotext $opts -- "$f" -
    (( multi )) && print -r -- ""
  done
}

Preview() {
  emulate -L zsh
  setopt local_options no_nomatch

  local force=0 text=0 f ext ok=0
  local -a files

  while (( $# )); do
    case "$1" in
      -f|--force) force=1; shift ;;
      -t|--text)  text=1; shift ;;
      -h|--help)
        print -r -- "Preview $PREVIEW_VERSION - open files in macOS Preview.app"
        print -r -- ""
        print -r -- "Usage: Preview [-f] [-t] [file ...]"
        print -r -- ""
        print -r -- "  file ...      one or more files to open"
        print -r -- "  (no args)     open a macOS file picker"
        print -r -- "  -f, --force   skip the extension compatibility check"
        print -r -- "  -t, --text    print PDF text to the terminal instead of"
        print -r -- "                opening the GUI (requires poppler)"
        print -r -- "  -h, --help    show this help"
        print -r -- "  -v, --version show version"
        return 0 ;;
      -v|--version) print -r -- "Preview $PREVIEW_VERSION"; return 0 ;;
      --) shift; files+=("$@"); break ;;
      -[^-]?*)
        # Expand clustered short flags: -tf becomes -t -f
        local -a cluster
        cluster=(${(s::)1[2,-1]})
        shift
        set -- ${cluster/#/-} "$@"
        continue ;;
      -*) print -u2 "Preview: unknown option: $1"; return 2 ;;
      *)  files+=("$1"); shift ;;
    esac
  done

  if (( text )) && ! (( $+commands[pdftotext] )); then
    print -u2 "Preview: -t needs pdftotext, which ships with poppler:"
    print -u2 "         brew install poppler"
    return 127
  fi

  if (( ! $#files )); then
    local picked prompt="Open in Preview:"
    (( text )) && prompt="Extract text from:"
    picked=$(osascript \
      -e "set fs to choose file with prompt \"$prompt\" with multiple selections allowed" \
      -e 'set out to ""' \
      -e 'repeat with f in fs' \
      -e 'set out to out & POSIX path of f & linefeed' \
      -e 'end repeat' \
      -e 'return out' 2>/dev/null) || return 1
    files=(${(f)picked})
    files=(${files:#})
    (( $#files )) || return 1
  fi

  local -a known valid
  known=($PREVIEW_EXTS ${PREVIEW_EXTRA_EXTS[@]})

  for f in $files; do
    if [[ -d "$f" ]]; then
      print -u2 "Preview: is a directory: $f"
      continue
    fi
    if [[ ! -e "$f" ]]; then
      print -u2 "Preview: no such file: $f"
      continue
    fi
    if [[ ! -r "$f" ]]; then
      print -u2 "Preview: not readable: $f"
      continue
    fi

    ext=${${f:t:e}:l}

    # Text mode only speaks PDF; -f still lets you try a misnamed file.
    if (( text )); then
      if (( ! force )) && [[ $ext != pdf ]]; then
        print -u2 "Preview: -t only works on PDFs, not ${ext:-that}: ${f:t}"
        print -u2 "         try it anyway with: Preview -tf \"$f\""
        continue
      fi
      valid+=("$f")
      continue
    fi

    if (( ! force )) && (( ! ${known[(Ie)$ext]} )); then
      print -u2 "Preview: ${ext:-that file type} is probably not supported: ${f:t}"
      print -u2 "         open it anyway with: Preview -f \"$f\""
      continue
    fi

    valid+=("$f")
  done

  (( $#valid )) || return 1

  if (( text )); then
    # Page only when writing to a terminal, so pipes and $(...) stay clean.
    if [[ -t 1 ]]; then
      local -a pager
      pager=(${=PREVIEW_PAGER:-${PAGER:-less}})
      _preview_pdftotext $valid | $pager
    else
      _preview_pdftotext $valid
    fi
    return 0
  fi

  for f in $valid; do
    open -a Preview -- "$f" && ok=1
  done

  (( ok ))
}
