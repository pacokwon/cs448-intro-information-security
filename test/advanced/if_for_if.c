#include <stdio.h>
#include <stdlib.h>

int main()
{
    int x = 3;
    int i = 0;
    int j = 0;
    char input[65536];
    fgets(input, sizeof(input), stdin);

    if(x >= 0)
    {
        for(i = 0; i < x; i++)
        {
            for(j = 0; j < i; j++)
            {
                int m = (i * j) / atoi(input);

                if(m >= 0)
                {
                    int k = x / m;
                }
            }
        }
    }
}
