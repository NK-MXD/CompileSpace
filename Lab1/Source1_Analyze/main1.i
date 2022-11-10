# 1 "main1.cpp"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 1 "<command-line>" 2
# 1 "main1.cpp"



int p =10;

int main(){
    int a, b, i, t, n;
    a=0;
    b=1;
    i=1;



    while(i<n){
        t=b;
        b=a+b;

        a=t;
        i=i+1;
    }
    return 0;
}
