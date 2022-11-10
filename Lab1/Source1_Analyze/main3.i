# 1 "main3.cpp"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 1 "<command-line>" 2
# 1 "main3.cpp"
int fibonacci(int n){
    if(n==1||n==2) return 1;
    else return fibonacci(n-1)+fibonacci(n-2);
}
