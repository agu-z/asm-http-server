#include <fcntl.h>
#include <netinet/in.h>
#include <stddef.h>
#include <stdio.h>
#include <sys/fcntl.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <unistd.h>

int main() {
  FILE *fp = fopen("out/const.s", "w");

  fprintf(fp, "// Do not manually edit this file\n\n");

#define add_const(name) fprintf(fp, ".equ %s, %d\n", #name, name);

  add_const(SYS_exit);
  add_const(SYS_read);
  add_const(SYS_write);
  add_const(SYS_socket);
  add_const(SYS_setsockopt);
  add_const(SYS_bind);
  add_const(SYS_listen);
  add_const(SYS_accept);
  add_const(SYS_close);
  add_const(SYS_gettimeofday);
  add_const(SYS_open);
  add_const(SYS_sendfile);
  add_const(SYS_fstat64);
  add_const(AF_INET);
  add_const(PF_INET);
  add_const(SOCK_STREAM);
  add_const(INADDR_ANY);
  add_const(SOL_SOCKET);
  add_const(SO_REUSEADDR);
  add_const(SO_REUSEPORT);
  add_const(O_RDONLY);

#define add_s_size(name)                                                       \
  fprintf(fp, ".equ sizeof_%s, %lu\n", #name, sizeof(struct name));
#define add_offset(struct_name, member)                                        \
  fprintf(fp, ".equ offsetof_%s, %lu\n", #member,                              \
          offsetof(struct struct_name, member));

  add_s_size(sockaddr_in);
  add_offset(sockaddr_in, sin_family);
  add_offset(sockaddr_in, sin_port);
  add_offset(sockaddr_in, sin_addr);
  add_s_size(timeval);
  add_s_size(timezone);
  add_s_size(stat);
  add_offset(stat, st_size);

  fprintf(fp, ".equ sizeof_int, %lu\n", sizeof(int));

  const int PORT = 4520;
  add_const(PORT);
  fprintf(fp, ".equ htons_PORT, %d\n", htons(PORT));

  fprintf(fp, "listening_msg:\n");
  fprintf(fp, "    .ascii \"Check out http://localhost:%d\\n\\n\"\n", PORT);
  fprintf(fp, "listening_msg_len = . - listening_msg\n");

  fclose(fp);

  return 0;
}
