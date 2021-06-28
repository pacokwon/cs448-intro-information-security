#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main()
{
    char input[65536];
    fgets(input, sizeof(input), stdin);

    if(strstr(input, "321") != NULL)
    {
        if(strstr(input, "850") != NULL)
        {
            int x = 0;
            int y = 100 / x;
        }
    }

    return 0;
}
