int divide(int a, int b){
    int c = 0;
    if (a >=0){
        c = 30/a;
    }
    else{
        c = 40/a;
    }
    return c;
}

int main()
{
    int x = 0;
    int y = 30;
    int z = divide(x, y);
}
