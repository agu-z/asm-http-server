.global _start
.align 2


_start:
    mov     x0, #1     // stdout
    adr     x1, hi
    mov     x2, #3
    mov     x16, #4    // write syscall
    svc     0

    mov     x0, #0
    mov     x16, #1    // exit syscall
    svc     0

hi:
    .ascii  "Hi\n"

