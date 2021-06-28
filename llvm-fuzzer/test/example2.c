<<<<<<< HEAD
int main()
{
    int x = 0;

    if(x >= 0)
    {
        int y = 20 / x;
    }
    else
    {
        int z = 30 / x;
    }
=======
#include <stdio.h>
#include <string.h>

int main() {
  char input[65536];
  fgets(input, sizeof(input), stdin);
  int x = 0;
  int y = 2;
  int z;
  if (strlen(input) % 7 == 0) {
    z = y / x;
  }

  if (strlen(input) % 13 == 0) {
    z = y / x;
  }

  return 0;
>>>>>>> fuzzer/master
}
