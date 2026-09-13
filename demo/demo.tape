# Regenerate the README GIF:  cd demo && vhs demo.tape
# invoice.pdf was made from invoice.txt with:
#   cupsfilter -i text/plain -m application/pdf invoice.txt > invoice.pdf
Output demo.gif

Set Shell zsh
Set FontSize 15
Set Width 900
Set Height 560
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms

Hide
Type "source rc.zsh" Enter
Sleep 500ms
Show

Type "Preview invoice.pdf" Sleep 600ms Enter
Sleep 1.2s

Type "Preview photo.jpg notes.txt" Sleep 600ms Enter
Sleep 2s

Type "Preview -t invoice.pdf | rg Total" Sleep 600ms Enter
Sleep 2s

Type "Preview -t invoice.pdf" Sleep 600ms Enter
Sleep 3.5s

Hide
Type "rm -f photo.jpg notes.txt" Enter
