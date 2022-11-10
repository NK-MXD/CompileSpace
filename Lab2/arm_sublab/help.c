#include"sylib.h"

const int initVal = 1;
int length = 3;

int fibonacci(int n){
    if(n==1||n==2) return initVal;
    else return fibonacci(n-1)+fibonacci(n-2);
}

int main() {
    int a,b;
    int cal,log,ral;
    a = getint();
    b = fibonacci(a);
    cal = a + b - b*2 + a/3 ;
    log = a > 5 && (b > 10 || a > b);
    ral = a >= b || (!a && (a + b) > 20 ) ;
    putint(b);
    printf("\ncal = a + b - b*2 + a/3 = %d\n",cal);
    printf("log = a > 5 && (b > 10 || a > b) = %d\n",log);
    printf("ral = a >= b || (!a && (a + b) > 20 ) = %d\n",ral);
    return 0;
}