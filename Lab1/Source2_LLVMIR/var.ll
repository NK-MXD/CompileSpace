;测试常量的定义与变量的定义
;输出声明
declare i32 @printf(i8*, ...)
@.str.1 = private unnamed_addr constant [8 x i8] c"i = %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [8 x i8] c"a = %d\0A\00", align 1
@.str.3 = private unnamed_addr constant [8 x i8] c"b = %d\0A\00", align 1
;全局的常量声明与初始化 const int a = 1;
@a = constant i32 1, align 4
define i32 @main() {
    ;变量声明 int i; 
    ;实际的用法是 int *i = (int *)malloc(sizeof(int));
    %1 = alloca i32, align 4
    ;变量初始化 i = 10;
    store i32 10, i32* %1, align 4
    ;局部的常量声明与初始化 const int b = 2;
    %2 = alloca i32,align 4
    store i32 2, i32* %2, align 4
    ;输出 i a
    %3 = load i32, i32* %1, align 4
    %4 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.1, i64 0, i64 0), i32 %3)
    %5 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.2, i64 0, i64 0), i32 1)
    %6 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.3, i64 0, i64 0), i32 2)
    ret i32 0
}