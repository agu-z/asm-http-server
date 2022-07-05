#include <netinet/in.h>
#include <stdio.h>
#include <sys/_types/_iovec_t.h>
#include <sys/socket.h>
#include <sys/syscall.h>

int main() {
  FILE *fp = fopen("out/const.s", "w");

  fprintf(fp, "// Do not manually edit this file\n\n");

#define add_const(name) fprintf(fp, ".equ %s, %d\n", #name, name);

  add_const(SYS_exit);
  add_const(SYS_write);
  add_const(SYS_socket);
  add_const(SYS_setsockopt);
  add_const(SYS_bind);
  add_const(SYS_listen);
  add_const(SYS_accept);
  add_const(SYS_close);
  add_const(AF_INET);
  add_const(PF_INET);
  add_const(SOCK_STREAM);
  add_const(INADDR_ANY);
  add_const(SOL_SOCKET);
  add_const(SO_REUSEADDR);
  add_const(SO_REUSEPORT);

  fprintf(fp, ".equ sizeof_int, %lu\n", sizeof(int));

  struct sockaddr_in _sockaddr_in;
  fprintf(fp, ".equ sizeof_sockaddr_in, %lu\n", sizeof(_sockaddr_in));

  struct sockaddr_storage _sockaddr_storage;
  fprintf(fp, ".equ sizeof_sockaddr_storage, %lu\n", sizeof(_sockaddr_storage));

  fprintf(fp, ".equ PORT, %d\n", htons(4520));

  fclose(fp);

  return 0;
}
