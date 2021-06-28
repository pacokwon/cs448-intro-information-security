#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void __dbz_sanitizer__(int divisor, int line, int col) {
  if (divisor == 0) {
    printf("Divide-by-zero detected at line %d and col %d\n", line, col);
    exit(1);
  }
}

int initialized = 0;

void initialize(char *covfile) {
  if (access(covfile, F_OK) != -1)
    unlink(covfile);
  initialized = 1;
}

void __coverage__(int line, int col) {
  char exe[1024];
  int ret = readlink("/proc/self/exe", exe, sizeof(exe) - 1);
  if (ret == -1) {
    fprintf(stderr, "Error: Cannot find /proc/self/exe\n");
    exit(1);
  }
  exe[ret] = 0;

  char covfile[1024];
  int len = strlen(exe);
  strncpy(covfile, exe, len);
  covfile[len] = 0;
  strcat(covfile, ".cov");

  if (!initialized)
    initialize(covfile);

  FILE *f = fopen(covfile, "a");
  fprintf(f, "%d,%d\n", line, col);
  fclose(f);
}
