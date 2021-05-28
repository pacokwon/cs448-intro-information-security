#include <stdio.h>

int main()
{
    char input[65536];
    fgets(input, sizeof(input), stdin);

    for(int i = 0; i < 100; i++)
    {
        int x = 100 / i;
    }

    return 0;
}
