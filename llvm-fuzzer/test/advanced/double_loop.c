<<<<<<< HEAD
int main()
{
    int ave = 0;
=======
#include <stdio.h>
#include <stdlib.h>

int main()
{
    int ave = 0;
    char input[65536];

    fgets(input, sizeof(input), stdin);
>>>>>>> fuzzer/master

    for(int i = 1; i < 100; i++)
    {
        for(int j = 0; j < 100; j++)
        {
            int k = i + j;
            int w = i - j;

<<<<<<< HEAD
=======
            w = atoi(input) + 10;
>>>>>>> fuzzer/master
            int z = k / w;

            if(i >= 10)
            {
                int m = k / i;
            }
        }
    }
}
