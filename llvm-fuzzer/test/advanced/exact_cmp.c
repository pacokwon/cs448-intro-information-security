#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main()
{
    char input[65536];
    fgets(input, sizeof(input), stdin);

    if(strncmp(input, "23456789", 8) == 0)
    {
        int x = 10;
        int y = x / 0;
    }

    return 0;
}
