#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void func(char* input)
{
    if(atoi(input) < 0)
    {
        int x = 10;
        int y = x / 0;
    }
}

int main()
{
    char input[65536];
    fgets(input, sizeof(input), stdin);

    func(input);

    return 0;
}
