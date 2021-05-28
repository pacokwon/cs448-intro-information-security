#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main()
{
    char input[65536];
    fgets(input, sizeof(input), stdin);

    if(strstr(input, "9876") != NULL)
    {
        int x = 500 / 0;
    }

    return 0;
}
