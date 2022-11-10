#include <iostream>
using namespace std;
//递归定义的斐波那契数列
int fibonacci(int n){
    if(n==1||n==2) return 1;
    else return fibonacci(n-1)+fibonacci(n-2);
}

int main() {
    int n;
    cin>>n;
    int res = fibonacci(n);
    std::cout << "fibonacci result: " << res << std::endl;
    return 0;
}