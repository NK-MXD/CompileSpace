;测试算术运算符
;输出声明
declare i32 @printf(i8*, ...)
@.str.1 = private unnamed_addr constant [8 x i8] c"c = %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [8 x i8] c"d = %d\0A\00", align 1
@.str.3 = private unnamed_addr constant [8 x i8] c"e = %d\0A\00", align 1
@.str.4 = private unnamed_addr constant [8 x i8] c"f = %d\0A\00", align 1
@.str.5 = private unnamed_addr constant [8 x i8] c"g = %d\0A\00", align 1

define i32 @main(){
    ;int a,b,c,d,e,f,g;
    %1 = alloca i32, align 4
    %2 = alloca i32, align 4
    %3 = alloca i32, align 4
    %4 = alloca i32, align 4
    %5 = alloca i32, align 4
    %6 = alloca i32, align 4
    %7 = alloca i32, align 4
    ;a = 10;
    ;b = 3;
    store i32 10, i32* %1, align 4
    store i32 3, i32* %2, align 4
    ;c = a + b;
    %8 = load i32, i32* %1, align 4
    %9 = load i32, i32* %2, align 4
    %10 = add i32 %8, %9
    store i32 %10, i32* %3
    ;d = b - a;
    %11 = load i32, i32* %2, align 4
    %12 = load i32, i32* %1, align 4
    %13 = sub i32 %11, %12
    store i32 %13, i32* %4
    ;e = a * b;
    %14 = load i32, i32* %1, align 4
    %15 = load i32, i32* %2, align 4
    %16 = mul i32 %14, %15
    store i32 %16, i32* %5
    ;f = a / b;
    %17 = load i32, i32* %1, align 4
    %18 = load i32, i32* %2, align 4
    %19 = sdiv i32 %17, %18
    store i32 %19, i32* %6
    ;g = a % b;
    %20 = load i32, i32* %1, align 4
    %21 = load i32, i32* %2, align 4
    %22 = srem i32 %20, %21
    store i32 %22, i32* %7
    ;输出
    %23 = load i32, i32* %3, align 4
    %24 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.1, i64 0, i64 0), i32 %23)
    %25 = load i32, i32* %4, align 4
    %26 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.2, i64 0, i64 0), i32 %25)
    %27 = load i32, i32* %5, align 4
    %28 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.3, i64 0, i64 0), i32 %27)
    %29 = load i32, i32* %6, align 4
    %30 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.4, i64 0, i64 0), i32 %29)
    %31 = load i32, i32* %7, align 4
    %32 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.5, i64 0, i64 0), i32 %31)
    ret i32 0
}