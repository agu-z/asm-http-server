.include "out/const.s"

.data

my_addr: 
    .ds sizeof_sockaddr_in

their_addr: 
    .ds sizeof_sockaddr_storage

.text

.global _start
.align 2

_start:
    adr     x0, hi
    mov     x1, 4
    bl      print

    // Get listener sock fd
    mov     x0, PF_INET
    mov     x1, SOCK_STREAM
    mov     x2, 0
    mov     x16, SYS_socket
    svc     0

    // Save returned sockfd
    mov     x10, x0

    // Allow reusing address
    mov     x0, x10
    mov     x1, SOL_SOCKET
    mov     x2, SO_REUSEADDR
    adr     x3, true
    mov     x4, sizeof_int
    mov     x16, SYS_setsockopt
    svc     0
    
    // Allow reusing port
    mov     x0, x10
    mov     x1, SOL_SOCKET
    mov     x2, SO_REUSEPORT
    adr     x3, true
    mov     x4, sizeof_int
    mov     x16, SYS_setsockopt
    svc     0
    
    // Construct sockaddr_in struct for bind
    adrp    x8, my_addr@page
    add     x8, x8, my_addr@pageoff
    mov     w9, 0           // my_addr.sin_len = 0
    strb    w9, [x8]  
    mov     w9, AF_INET     // my_addr.sin_family = AF_INET
    strb    w9, [x8, 1]
    mov     w9, PORT        // my_addr.sin_port = PORT
    strh    w9, [x8, 2]
    mov     w9, INADDR_ANY  // my_addr.sin_addr.s_addr = INADDR_ANY
    strb    w9, [x8, 4]
    mov     w9, 0           // my_addr.sin_zero = 0
    strb    w9, [x8, 8]      

    // Bind port
    mov     x0, x10
    mov     x1, x8
    mov     x2, sizeof_sockaddr_in 
    mov     x16, SYS_bind
    svc     0
    
    // Listen
    mov     x0, x10
    mov     x1, 10
    mov     x16, SYS_listen
    svc     0

    // Accept
    adrp    x11, their_addr@page
    add     x11, x11, their_addr@pageoff
    mov     x0, x10
    mov     x1, x11
    adr     x2, sizeof_sockaddr_storage_p
    mov     x16, SYS_accept
    svc     0

    // Store sockfd for this specific connection
    mov     x12, x0

    // TODO: Handle request

    // Close connection fd
    mov     x0, x12
    mov     x16, SYS_close
    svc     0
    
    // Close listening fd
    mov     x0, x10
    mov     x16, SYS_close
    svc     0

    // Exit 
    mov     x0, 0
    mov     x16, SYS_exit
    svc     0

print:
    mov     x2, x1
    mov     x1, x0
    mov     x0, 1
    mov     x16, SYS_write
    svc     0
    ret

hi:
    .ascii  "Hi!\n"

true:
    .word   1

sizeof_sockaddr_storage_p:
    .word   sizeof_sockaddr_storage
