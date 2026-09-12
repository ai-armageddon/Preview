# Preview

Open files in macOS **Preview.app** straight from your shell — no `open -a Preview` boilerplate.

```sh
Preview report.pdf          # opens in Preview
Preview *.png               # opens all of them
Preview                     # file picker, opens whatever you select
Preview -t report.pdf       # read the PDF as text, no GUI
```

## Why a function and not an alias

On a case-insensitive filesystem (the APFS default), `preview` and `Preview` would both
resolve to the same thing on PATH. zsh looks up **function names case-sensitively before
falling through to PATH**, so defining `Preview()` gives you a capitalized command that
can't collide with a lowercase binary of the same name.

## Install

```sh
git clone https://github.com/ai-armageddon/Preview.git
cd Preview
./install.sh
```

The installer copies `preview.zsh` to `~/.local/share/preview/` and appends a source line
to your `~/.zshrc`. Then reload:

```sh
source ~/.zshrc
```

### Manual install

Drop `preview.zsh` anywhere and source it:

```sh
# ~/.zshrc
[ -f "$HOME/.local/share/preview/preview.zsh" ] && source "$HOME/.local/share/preview/preview.zsh"
```

If you keep a functions directory that's already globbed by your zshrc, just copy the file
in and you're done:

```sh
cp preview.zsh ~/.zsh/functions/
```

## Usage

```
Preview [-f] [-t] [file ...]

  file ...        one or more files to open
  (no args)       open a macOS file picker (multi-select allowed)
  -f, --force     skip the extension compatibility check
  -t, --text      print PDF text to the terminal instead of opening the GUI
  -h, --help      show help
  -v, --version   show version
```

Short flags cluster, so `-tf` is the same as `-t -f`.

Behavior notes:

- Multiple files open in Preview together, as tabs or a single window depending on your
  Preview settings.
- Extension matching is case-insensitive, so `.HEIC` and `.heic` both work.
- Directories, missing files, and unreadable files are reported to stderr and skipped —
  the rest of the list still opens.
- Exit status is `0` if at least one file opened, `1` if none did, `2` on a bad option,
  `127` if `-t` was used without poppler installed.
  Handy in scripts: `Preview "$f" || echo "nothing opened"`.

## Text mode

Sometimes you don't want a window — you want the words. `-t` pipes the PDF through
[`pdftotext`](https://poppler.freedesktop.org/) and prints them:

```sh
Preview -t invoice.pdf                  # read it in your pager
Preview -t invoice.pdf | rg 'Total'     # grep it
text=$(Preview -t paper.pdf)            # capture it
Preview -t *.pdf                        # each file gets a ==> name <== header
```

This needs poppler, which is not required for anything else:

```sh
brew install poppler
```

Without it, `-t` exits `127` and tells you that command. Every other mode keeps working.

Details worth knowing:

- **Paging is TTY-aware.** Output goes through `less` only when stdout is a terminal, so
  pipes and `$(...)` stay clean and unpaginated. Override with `PREVIEW_PAGER` (or your
  existing `$PAGER`).
- **Layout is preserved** by default via `pdftotext -layout`, which keeps tables and
  columns readable. Override the flags entirely with `PREVIEW_PDFTOTEXT_OPTS`:

  ```sh
  PREVIEW_PDFTOTEXT_OPTS=-raw Preview -t doc.pdf    # raw content-stream order
  PREVIEW_PDFTOTEXT_OPTS='-f 2 -l 5' Preview -t doc.pdf   # pages 2 through 5
  ```

- **PDFs only.** `-t` refuses other file types, since `pdftotext` can't read them. If a PDF
  is misnamed, force it with `-tf`.
- **Scanned PDFs produce nothing.** `pdftotext` extracts an existing text layer; it is not
  OCR. If a page is just a photo of text, you'll get empty output — that's the file's
  fault, not the tool's. Open it in the GUI instead, or run it through an OCR tool first.

## Testing

```sh
./test.zsh
```

38 assertions covering both modes. `open` and `pdftotext` are stubbed, so nothing launches
on screen and poppler isn't needed for most of it. One test builds a real PDF with
`cupsfilter` and extracts from it end to end when poppler is available.

## Compatibility check

Before handing a file to Preview, the extension is checked against an allowlist
(`PREVIEW_EXTS`) covering PDF/PostScript, common raster formats, JPEG 2000, HEIC/AVIF/WebP,
PSD, SVG, netpbm, and a long list of camera raw formats.

**This is a heuristic, not ground truth.** It's an extension allowlist, so it can produce
false negatives for formats Preview genuinely handles, and it says nothing about a file's
actual contents. Two escape hatches:

```sh
Preview -f mystery.xyz              # one-off bypass
```

```sh
# ~/.zshrc, before sourcing preview.zsh — permanently teach it new extensions
PREVIEW_EXTRA_EXTS=(fits pcx dpx)
```

If you hit a false negative worth fixing for everyone, open an issue or a PR adding the
extension to `PREVIEW_EXTS`.

## Requirements

- macOS (uses `open -a Preview`, and `osascript` for the picker)
- zsh
- [poppler](https://poppler.freedesktop.org/) — **optional**, only for `-t`:
  `brew install poppler`

## Uninstall

Remove the source line from `~/.zshrc` and delete the directory:

```sh
rm -rf ~/.local/share/preview
```

## License

MIT — see [LICENSE](LICENSE).
