<<<<<<< HEAD
int main()
{
=======
#include <stdio.h>

int main()
{
    char input[65536];
    fgets(input, sizeof(input), stdin);

>>>>>>> fuzzer/master
    int x = 0;

    int z = 10 / x; // Error
}
