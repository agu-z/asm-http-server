.include "out/const.s"

.data

my_addr: 
    .ds sizeof_sockaddr_in

.equ REQ_BUFFER_SIZE, 1024

request:
    .ds REQ_BUFFER_SIZE

.text

.align 2
.global _start


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

    // Print listening message
    mov     x0, 1
    adr     x1, listening_msg
    mov     x2, listening_msg_len
    sys     write

accept_connection:
    // Accept
    mov     x0, x10
    mov     x1, xzr
    mov     x2, xzr
    sys     accept

    // Store fd for this specific connection
    mov     x11, x0
 
    // Read request
    dadr    x12, request
    mov     x0, x11
    mov     x1, x12
    mov     x2, REQ_BUFFER_SIZE
    sys     read

    // Print request to stdout
    mov     x0, 1
    mov     x1, x12
    mov     x2, REQ_BUFFER_SIZE
    sys     write

    ldr     x13, [x12]
    adr     x14, get_prefix
    ldr     x14, [x14]
    and     x13, x13, x14
    cmp     x13, x14
    b.ne    method_not_allowed

    adr     x1, http_response
    mov     x2, http_response_len
    b       write_and_close

method_not_allowed:
    adr     x1, only_get_supported
    mov     x2, only_get_supported_len

write_and_close:
    mov     x0, x11
    sys     write

    // Close connection fd
    mov     x0, x11
    sys     close

    // Accept another connection
    b accept_connection

true:
    .word   1

http_response:
    .ascii "HTTP/1.1 200 OK\nContent-Type: text/html\n\r\n<h1>Hello from Apple Silicon!</h1>\n"

http_response_len = . - http_response

.align 4

get_prefix:
    .ascii "GET /"

get_prefix_len = . - get_prefix

.align 4

only_get_supported:
    .ascii "HTTP/1.1 405 Method Not Allowed\n\r\nOnly GET method supported\n"

only_get_supported_len = . - only_get_supported

