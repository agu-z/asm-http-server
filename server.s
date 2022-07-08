.include "out/const.s"

.data

my_addr: 
    .ds sizeof_sockaddr_in

.equ REQ_BUFFER_SIZE, 1024

request:
    .ds REQ_BUFFER_SIZE

.text

.global _start
.align 2


// Gets the address of writable memory
.macro dadr Xn, name
    adrp    \Xn, \name@page
    add     \Xn, \Xn, \name@pageoff
.endm

// Performs a syscall by name
.macro sys name
    mov     x16, SYS_\name
    svc     0
.endm


_start:
    mov     x0, 1
    adr     x1, listening_msg
    mov     x2, listening_msg_len
    sys     write

    // Get listener sock fd
    mov     x0, PF_INET
    mov     x1, SOCK_STREAM
    mov     x2, xzr
    sys     socket

    // Save returned sockfd
    mov     x10, x0

    // Allow reusing address
    mov     x0, x10
    mov     x1, SOL_SOCKET
    mov     x2, SO_REUSEADDR
    adr     x3, true
    mov     x4, sizeof_int
    sys     setsockopt
    
    // Allow reusing port
    mov     x0, x10
    mov     x1, SOL_SOCKET
    mov     x2, SO_REUSEPORT
    adr     x3, true
    mov     x4, sizeof_int
    sys     setsockopt
    
    // Construct sockaddr_in struct for bind
    dadr    x1, my_addr
    mov     w9, AF_INET
    strb    w9, [x1, offsetof_sin_family]
    mov     w9, htons_PORT
    strh    w9, [x1, offsetof_sin_port]
    mov     w9, INADDR_ANY
    strb    w9, [x1, offsetof_sin_addr]

    // Bind port
    mov     x0, x10
    mov     x2, sizeof_sockaddr_in 
    sys     bind
    
    // Listen
    mov     x0, x10
    mov     x1, 10
    sys     listen

    // Accept
    mov     x0, x10
    mov     x1, xzr
    mov     x2, xzr
    sys     accept

    // Store file descriptor for this specific connection
    mov     x11, x0

    // Read request
    dadr    x1, request
    mov     x2, REQ_BUFFER_SIZE
    sys     read

    // Print request to stdout
    mov     x0, 1
    dadr    x1, request
    mov     x2, REQ_BUFFER_SIZE
    sys     write

    // Write response
    mov     x0, x11
    adr     x1, http_response
    mov     x2, http_response_len
    sys     write

    // Close connection fd
    mov     x0, x11
    sys     close
 
    // Close listening fd
    mov     x0, x10
    sys     close

    // Exit with code 0
    mov     x0, xzr
    sys     exit

true:
    .word   1

http_response:
    .ascii "HTTP/1.1 200 OK\nContent-Type: text/html\n\r\n<h1>Hello from Apple Silicon!</h1>\n"

http_response_len = . - http_response
