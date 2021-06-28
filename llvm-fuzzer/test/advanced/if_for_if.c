<<<<<<< HEAD
=======
#include <stdio.h>
#include <stdlib.h>

>>>>>>> fuzzer/master
int main()
{
    int x = 3;
    int i = 0;
    int j = 0;
<<<<<<< HEAD
=======
    char input[65536];
    fgets(input, sizeof(input), stdin);
>>>>>>> fuzzer/master

    if(x >= 0)
    {
        for(i = 0; i < x; i++)
        {
<<<<<<< HEAD

            for(j = 0; j < i; j++)
            {
                int m = (i * j) / i;
=======
            for(j = 0; j < i; j++)
            {
                int m = (i * j) / atoi(input);
>>>>>>> fuzzer/master

                if(m >= 0)
                {
                    int k = x / m;
                }
            }
        }
    }
<<<<<<< HEAD
    else
    {
        x = -x;

        for(i = 0; i < x; i++)
        {

            for(j = 0; j > i; j--)
            {
                int m = (i * j) / i;

                if(m >= 0)
                {
                    int k = x / m;
                }
            }
        }
    }

=======
>>>>>>> fuzzer/master
}
