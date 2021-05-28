#include <stdio.h>
#include <stdlib.h>

int main()
{
    char input[65536];
    fgets(input, sizeof(input), stdin);
    int x = 20;

    int y = x * atoi(input);

    int z = x / y;
}
