int main()
{
    int x = 3;
    int i = 0;
    int j = 0;

    if(x >= 0)
    {
        for(i = 0; i < x; i++)
        {

            for(j = 0; j < i; j++)
            {
                int m = (i * j) / i;

                if(m >= 0)
                {
                    int k = x / m;
                }
            }
        }
    }
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

}
