<<<<<<< HEAD
int main() {
  int x = 10;
  int y = 10 + x;
  int z = x - 10;
  int w = y / z;
=======
#include <stdio.h>
#include <string.h>

int main() {
  char input[65536];
  fgets(input, sizeof(input), stdin);
  int x = 0;
  int y = 2;
  int z = y / x;
>>>>>>> fuzzer/master
  return 0;
}
