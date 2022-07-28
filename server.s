.include "out/const.s"
// The above includes many constants needed to talk to the OS
// out/const.s is automatically generated by make_const.c

.data

my_addr: .ds sizeof_sockaddr_in

.equ req_buf_size, 1024
req_buf: .ds req_buf_size

current_timeval: .ds sizeof_timeval

.equ current_time_str_size, 16
current_time_str: .ds current_time_str_size

stat_buf: .ds sizeof_stat

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


// Socket setup


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


// Accept loop


accept_connection:
    mov     x0, x10
    mov     x1, xzr
    mov     x2, xzr
    sys     accept

    // Store fd for this specific connection
    mov     x11, x0

    // Read request
    dadr    x12, req_buf
    mov     x0, x11
    mov     x1, x12
    mov     x2, req_buf_size
    sys     read

    // Print request to stdout
    mov     x0, 1
    mov     x1, x12
    mov     x2, req_buf_size
    sys     write

    // Match routes and jump to their handlers

    adr     x0, index_route
    adr     x1, handle_index
    bl      match_route

    adr     x0, time_route
    adr     x1, handle_time
    bl      match_route

    adr     x0, cat_gif_route
    adr     x1, handle_cat_gif
    bl      match_route

    // If we get here, nothing was matched. Return 404.

    adr     x1, not_found_response
    mov     x2, not_found_response_len
    bl      write_response
    b       end_response

    write_response:
        mov     x0, x11
        sys     write
        ret

    end_response:
        mov     x0, x11
        adr     x1, newline
        mov     x2, 1
        sys     write

        // Close connection fd
        mov     x0, x11
        sys     close

        // Accept another connection
        b accept_connection


    match_route:
        mov     x14, 0

    match_route_char:
        // Load the next request char and expected route char
        ldrb    w15, [x12, x14]
        ldrb    w16, [x0, x14]
        cmp     w16, wzr            // check for NUL terminator
        b.eq    end_of_route

        // Compare request and route chars
        cmp     w15, w16
        b.ne    route_not_matched

        // Char matched
        add     x14, x14, 1

        // Keep looping if we haven't reached the end of the buffer
        cmp     x14, req_buf_size
        b.lt    match_route_char

        b       route_not_matched

    end_of_route:
        cmp     w15, ' '
        b.ne    route_not_matched
        // Route matched, jump to handler
        br      x1

    route_not_matched:
        ret


// Route handlers


handle_index:
    adr     x1, ok_html_response
    mov     x2, ok_html_response_len
    bl      write_response

    adr     x1, index_response
    mov     x2, index_response_len
    bl      write_response

    b       end_response

handle_time:
    dadr    x13, current_timeval
    mov     x0, x13
    mov     x1, xzr
    sys     gettimeofday

    adr     x1, ok_html_response
    mov     x2, ok_html_response_len
    bl      write_response

    ldr     w0, [x13]
    dadr    x1, current_time_str
    mov     x4, current_time_str_size
    mov     x6, 10

    digit_to_ascii:
        // Extract last digit by dividing by 10 (x6)
        mov     x3, x0
        udiv    x0, x0, x6
        msub    x5, x0, x6, x3

        // Get the ascii code by adding 0x30
        add     x5, x5, 0x30
        strb    w5, [x1, x4]

        // Write the response if we've reached the first digit
        cmp     x0, 1
        b.lt    write_time_response

        // Move pointer to the left
        sub     x4, x4, 1

        b       digit_to_ascii

    write_time_response:
        add     x1, x1, x4
        mov     x3, current_time_str_size + 1
        sub     x2, x3, x4
        bl      write_response

        b       end_response


handle_cat_gif:
    adr     x1, ok_gif_response
    mov     x2, ok_gif_response_len
    bl      write_response

    // Open cat.gif
    adr     x0, cat_gif_path
    mov     x1, O_RDONLY
    sys     open

    // Get its size using stat
    mov     x13, x0
    dadr    x14, stat_buf
    mov     x1, x14
    sys     fstat64 // not just fstat! took me a while to figure out

    // Let the OS blast the file out the socket
    mov     x0, x13
    mov     x1, x11
    mov     x2, xzr
    add     x3, x14, offsetof_st_size
    mov     x4, xzr
    mov     x5, xzr
    sys     sendfile // such a cool syscall

    mov     x0, x13
    sys     close

    b       end_response


true: .word   1

zero_offset: .byte   0

.align 4
newline: .ascii "\n"

.align 4
index_route: .asciz "GET /"

.align 4
time_route: .asciz "GET /time"

.align 4
cat_gif_route: .asciz "GET /cat.gif"

.align 4
cat_gif_path: .asciz "cat.gif"

.align 4
not_found_response:
    .ascii "HTTP/1.1 404 Not Found\n\r\nNot Found"

not_found_response_len = . - not_found_response

.align 4
ok_html_response:
    .ascii "http/1.1 200 OK\nContent-Type: text/html\n\r\n"

ok_html_response_len = . - ok_html_response

.align 4
ok_gif_response:
    .ascii "HTTP/1.1 200 OK\nContent-Type: image/gif\n\r\n"

ok_gif_response_len = . - ok_gif_response

.align 4
index_response:
    .ascii "<img src=\"cat.gif\"><p>This wonderful cat gif is brought to you by ARM64 assembly.</p><p>Also, check out this dynamic <a href=\"/time\">time page</a>.</p>"

index_response_len = . - index_response

