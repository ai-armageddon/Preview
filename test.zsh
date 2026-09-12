#!/usr/bin/env zsh
# Test suite for preview.zsh
#
#   ./test.zsh
#
# `open` and `pdftotext` are stubbed, so nothing actually launches and poppler
# is not required except for the tests tagged [poppler], which skip without it.

emulate -L zsh
setopt no_nomatch

SRC="${0:A:h}/preview.zsh"
[[ -f $SRC ]] || { print -u2 "cannot find preview.zsh next to test.zsh"; exit 1; }

typeset -g PASS=0 FAIL=0 SKIP=0
typeset -g TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Stubs. `open` records its args; `pdftotext` emits predictable text.
open()      { print -r -- "OPEN:$*"; }
pdftotext() { print -r -- "PDFTOTEXT:$*"; }

source "$SRC"

ok()   { PASS=$((PASS+1)); print -r -- "  ok   $1"; }
no()   { FAIL=$((FAIL+1)); print -r -- "  FAIL $1"; print -r -- "       $2"; }
skip() { SKIP=$((SKIP+1)); print -r -- "  skip $1"; }

# assert <name> <expected-substring> <actual>
assert() {
  [[ $3 == *$2* ]] && ok "$1" || no "$1" "expected to contain: $2
       actual: $3"
}
# refute <name> <forbidden-substring> <actual>
refute() {
  [[ $3 != *$2* ]] && ok "$1" || no "$1" "expected NOT to contain: $2
       actual: $3"
}
# assert_rc <name> <expected-rc> <actual-rc>
assert_rc() {
  (( $2 == $3 )) && ok "$1" || no "$1" "expected rc=$2, got rc=$3"
}

cd "$TMP"
touch a.png b.PDF c.HEIC weird.xyz doc.pdf "my file.png"
mkdir adir
touch noread.png && chmod 000 noread.png

print -r -- "meta"
assert "version flag"      "$PREVIEW_VERSION" "$(Preview -v)"
assert "help mentions -t"  "-t, --text"       "$(Preview --help)"
assert_rc "help rc" 0 "$(Preview --help >/dev/null; print $?)"

print "\nopening files"
assert "single file"        "OPEN:-a Preview -- a.png"     "$(Preview a.png)"
assert "uppercase ext"      "OPEN:-a Preview -- b.PDF"     "$(Preview b.PDF)"
assert "spaces in name"    "OPEN:-a Preview -- my file.png" "$(Preview 'my file.png')"
out=$(Preview a.png b.PDF c.HEIC)
assert "multi 1/3"          "a.png" "$out"
assert "multi 2/3"          "b.PDF" "$out"
assert "multi 3/3"          "c.HEIC" "$out"
assert_rc "success rc" 0 "$(Preview a.png >/dev/null; print $?)"

print "\ncompatibility check"
assert "unsupported warns"  "probably not supported" "$(Preview weird.xyz 2>&1)"
refute "unsupported no open" "OPEN:"                 "$(Preview weird.xyz 2>&1)"
assert_rc "unsupported rc" 1 "$(Preview weird.xyz 2>/dev/null; print $?)"
assert "force opens"        "OPEN:-a Preview -- weird.xyz" "$(Preview -f weird.xyz)"
assert "long force opens"   "OPEN:-a Preview -- weird.xyz" "$(Preview --force weird.xyz)"
PREVIEW_EXTRA_EXTS=(xyz)
assert "extra exts opens"   "OPEN:-a Preview -- weird.xyz" "$(Preview weird.xyz)"
PREVIEW_EXTRA_EXTS=()

print "\nbad input"
assert "directory"          "is a directory"  "$(Preview adir 2>&1)"
assert "missing file"       "no such file"    "$(Preview nope.png 2>&1)"
assert "unreadable file"    "not readable"    "$(Preview noread.png 2>&1)"
assert "unknown option"     "unknown option"  "$(Preview --bogus 2>&1)"
assert_rc "unknown option rc" 2 "$(Preview --bogus 2>/dev/null; print $?)"
assert "partial success"    "OPEN:-a Preview -- a.png" "$(Preview nope.png a.png 2>/dev/null)"
assert_rc "partial rc" 0 "$(Preview nope.png a.png >/dev/null 2>&1; print $?)"
assert "-- terminator"      "OPEN:-a Preview -- a.png" "$(Preview -- a.png)"

print "\nclustered flags"
assert "-tf clusters"       "PDFTOTEXT:"      "$(Preview -tf weird.xyz 2>&1)"
assert "bad cluster errors" "unknown option"  "$(Preview -zq a.png 2>&1)"

print "\ntext mode (stubbed)"
assert "text uses pdftotext" "PDFTOTEXT:"     "$(Preview -t doc.pdf)"
assert "text passes -layout" "-layout"        "$(Preview -t doc.pdf)"
assert "text long flag"      "PDFTOTEXT:"     "$(Preview --text doc.pdf)"
refute "text does not open"  "OPEN:"          "$(Preview -t doc.pdf)"
assert "text rejects nonpdf" "only works on PDFs" "$(Preview -t a.png 2>&1)"
assert_rc "text nonpdf rc" 1 "$(Preview -t a.png 2>/dev/null; print $?)"
assert "text respects opts"  "-raw"           "$(PREVIEW_PDFTOTEXT_OPTS=-raw Preview -t doc.pdf)"
out=$(Preview -t doc.pdf b.PDF)
assert "multi-pdf header"    "==> doc.pdf <==" "$out"

print "\nmissing poppler"
# Empty PATH in a clean subshell, so pdftotext genuinely isn't findable.
out=$(PATH=/nonexistent /bin/zsh -fc "source ${(q)SRC}; Preview -t ${(q)TMP}/doc.pdf" 2>&1)
rc=$(PATH=/nonexistent /bin/zsh -fc "source ${(q)SRC}; Preview -t ${(q)TMP}/doc.pdf" >/dev/null 2>&1; print $?)
assert "suggests brew install" "brew install poppler" "$out"
assert_rc "missing poppler rc" 127 "$rc"

print "\nreal pdftotext [poppler]"
unfunction pdftotext
if (( $+commands[pdftotext] )); then
  # Build a tiny real PDF via Preview-independent tooling.
  printf 'Hello Preview test\n' > src.txt
  if /usr/sbin/cupsfilter src.txt > real.pdf 2>/dev/null && [[ -s real.pdf ]]; then
    assert "extracts real text" "Hello Preview test" "$(Preview -t real.pdf 2>/dev/null)"
    assert_rc "real text rc" 0 "$(Preview -t real.pdf >/dev/null 2>&1; print $?)"
  else
    skip "real PDF extraction (could not generate a test PDF)"
  fi
else
  skip "real PDF extraction (poppler not installed)"
fi

print "\n$PASS passed, $FAIL failed, $SKIP skipped"
(( FAIL == 0 ))
