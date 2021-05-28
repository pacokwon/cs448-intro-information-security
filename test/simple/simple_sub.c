#include <stdio.h>
#include <stdlib.h>

int main()
{
    char input[65536];
    int x = 7;
    int y;
    fgets(input, sizeof(input), stdin);

    y = x - atoi(input);

    int z = 20 / y; // Error
}
