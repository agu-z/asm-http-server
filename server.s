.include "out/const.s"

.text

.global _start
.align 2

_start:
    adr     x0, hi
    mov     x1, 4
    bl      print

    mov     x0, 0
    mov     x16, SYS_exit
    svc     0

print:
    mov     x2, x1
    mov     x1, x0
    mov     x0, #1
    mov     x16, SYS_write
    svc     0
    ret

hi:
    .ascii  "Hi!\n"
