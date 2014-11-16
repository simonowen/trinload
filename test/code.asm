    org &8000
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
