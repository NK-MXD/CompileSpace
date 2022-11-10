//#include"sylib.c"

int main() {
    int a,b,c_n;
    int c[3];
    a = getint();
    b = getch();
    c_n = getarray(c);
    putint(a);
    putch(b);
    putarray(c_n,c);
    printf("数组中元素个数为: %d\n",c_n);
    return 0;
}