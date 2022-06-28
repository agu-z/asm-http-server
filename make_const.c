#include <stdio.h>
#include <sys/syscall.h>

const char *HEADER_TEXT = "// Do not manually edit this file\n\n";

int main() {
  FILE *fp = fopen("out/const.s", "w");

  fprintf(fp, "// Do not manually edit this file\n\n");

  #define add_const(name) fprintf(fp, ".equ %s, %d\n", #name, name);

  add_const(SYS_exit);
  add_const(SYS_write);

  fclose(fp);

  return 0;
}
