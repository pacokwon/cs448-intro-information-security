<<<<<<< HEAD
int main()
{
    int x = 10;
    int y = 100;

=======
#include <stdio.h>
#include <stdlib.h>

int main()
{
    char input[65536];
    int x = 10;
    int y = 100;

    fgets(input, sizeof(input), stdin);
>>>>>>> fuzzer/master

    if(x / y == 2)
    {
        int z = x * 100;
    }
    else if(x + y >= 10)
    {
        int z = y / x;
        int k = 0;

        for(int i = 0; i < x; i++)
        {
            z = (x + x) / i;
            k += z;
        }

        int interval_safe = x / k;
    }
    else
    {
<<<<<<< HEAD
        int k = x - y;
=======
        int k = x - atoi(input);
>>>>>>> fuzzer/master

        int err = (x + y) / k;
    }

}
