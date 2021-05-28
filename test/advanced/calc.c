#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char* substr(char* input, int start, int end)
{
    char* new = malloc(sizeof(char)*(end - start));

    strncpy(new, input, end - start);

    return new;
}

int job(char* input)
{
    char op = '+';
    int idx = -1;

    for(int i = 0; i < 65536; i++)
    {
        if(input[i] == op)
        {
            idx = i;
            break;
        }
    }

    if(idx == -1)
        return -1;

    int operand1 = atoi(substr(input, 0, idx));
    int operand2 = atoi(substr(input, idx+1, 65536));

    return operand1 + operand2;
}

int main()
{
    char input[65536];
    fgets(input, sizeof(input), stdin);

    int val = job(input);

    if(val > 1000)
    {
        int x = 10;
        int y = x / 0;
    }

    return 0;
}
