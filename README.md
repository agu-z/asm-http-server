# asm-http-server

I wrote an HTTP server in ARM64 Assembly to have fun with some low level stuff.

![A gif recording demonstrating the server working](.demo.gif)

You can check out the code at [`server.s`](server.s).

I'm talking to macOS directly through syscalls, which you're not supposed to do since, being a private API, they can change at any point. However, I did so anyway since I just wanted to explore the lowest level.

To prevent hardcoding all the constants needed to talk to the OS, [I'm generating](make_const.c) a `const.s` file from the C headers of the system lib. I cannot distribute binaries, but at least I should have better luck building it in the future.

## Things I may do:

- Use `fork` to handle many connections at once
- Handle `SIGINT` to gracefully close the server
- Send `Content-Length`

# Running

On an Apple Silicon mac, run:

```sh
$ make
```

...and check out [http://localhost:4520](http://localhost:4520).

# Resources

Some stuff that helped me get this working:

- [AArch64 Instruction Set Architecture](https://developer.arm.com/documentation/102374/0100/?lang=en)
- [x86 and A64 common instructions comparison](https://modexp.wordpress.com/2018/10/30/arm64-assembly/#x86table)
- [Assembly Preprocessor Directives](https://modexp.wordpress.com/2018/10/30/arm64-assembly/#directives)
- [Beej's Guide to Network Programming (for C)](https://beej.us/guide/bgnet/html/index.html)
- [LLDB cheat sheet](https://www.nesono.com/sites/default/files/lldb%20cheat%20sheet.pdf)
- [HTTP flow](https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview#http_flow)

Also just running `man <SYSCALL>` can be super helpful. I wish we had something like that for modern stuff :)
