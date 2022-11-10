// clang -E -Xclang -ast-dump example1.cpp
//test const gloal var define
const int a = 10, b = 5;

int main(){
    return b;
}