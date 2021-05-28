#include <stdio.h>

int main()
{
    char input[65536];
    fgets(input, sizeof(input), stdin);
    int x = 0;

    if(x >= 0)
    {
        int y = 20 / x;
    }
    else
    {
        int z = 30 / x;
    }
}
