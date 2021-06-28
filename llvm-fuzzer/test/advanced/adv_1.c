<<<<<<< HEAD
int main()
{
    int x = 0;
    int t = 10;

=======
#include <stdio.h>
#include <stdlib.h>

int main()
{
    char input[65536];
    int x = 0;
    int t = 10;

    fgets(input, sizeof(input), stdin);
    x = atoi(input);

>>>>>>> fuzzer/master
    if(x >= 10)
    {
        int y = 100 / x;
        int w = x / 0;
        t = 10 - x;
    }
    else if(x <= -10)
    {
        int y = 100 / x;

        t = 10 + x - x + x;
    }
    else if(x >= 0)
    {
        int y = 100 / x;
        t = t * x;
    }
    else
    {
        int y = 100 / x;
        t = t / y;
    }

    t = x / t;
}
