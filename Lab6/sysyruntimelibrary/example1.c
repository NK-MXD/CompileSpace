int getint();

int main(){
    int a = getint();
    return 0;
}
// clang -E -Xclang -ast-dump example1.cpp
// X86下静态链接指令: gcc example1.c -o example1 sylib.a
// 注: libsysy.a是arm架构下的静态链接库