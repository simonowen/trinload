    org &8000

    dump $            ; not needed by test.bat/trinload.py, but needed if running
    autoexec          ; `samdisk code.dsk trinity:` (e.g. via vscode-pyz80)

    ld  bc,50
    ld  a,7
loop1:
    out (254),a
    ld  b,c
loop2:
    halt
    djnz loop2
    dec a
    jp  p,loop1
    ret
