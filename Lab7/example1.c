// clang -E -Xclang -ast-dump example1.c
// clang -emit-llvm -S example1.c -o example1.ll
//test const gloal var define
// 汇编	llc example.bc -o example.s
//	执行 gcc example.s -o example
// 中间代码输入输出执行 clang -o build/compiler example.ll sysyruntimelibrary/sylib.c
// 可执行程序 clang example.ll sysyruntimelibrary/sylib.c -o example
// 执行 build/compiler example.ll
//clang 中间代码执行文件生成 clang -emit-llvm -S example1.c -o example1.ll
// 汇编代码生成 arm-linux-gnueabihf-gcc -mcpu=cortex-a72 -S example1.c sysyruntimelibrary/libsysy.a -o example1.S
// 汇编可执行文件 arm-linux-gnueabihf-gcc -mcpu=cortex-a72 example1.S sysyruntimelibrary/libsysy.so -o example1
// arm-linux-gnueabihf-gcc -mcpu=cortex-a72 -o example example.s  sysyruntimelibrary/libsysy.a
// 汇编文件执行 qemu-arm example <example.in
// reference: https://zhuanlan.zhihu.com/p/20085048
//test array define
int main(){
    int a[4][2] = {};
    int b[4][2] = {1, 2, 3, 4, 5, 6, 7, 8};
    int c[4][2] = {{1, 2}, {3, 4}, {5, 6}, {7, 8}};
    int d[4][2] = {1, 2, {3}, {5}, 7 , 8};
    int e[4][2] = {{d[2][1], c[2][1]}, {3, 4}, {5, 6}, {7, 8}};
    return e[3][1] + e[0][0] + e[0][1] + a[2][0];
}