;测试关系运算符
;输出声明
declare i32 @printf(i8*, ...)
@.str.1 = private unnamed_addr constant [8 x i8] c"c = %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [8 x i8] c"d = %d\0A\00", align 1
@.str.3 = private unnamed_addr constant [8 x i8] c"e = %d\0A\00", align 1
@.str.4 = private unnamed_addr constant [8 x i8] c"f = %d\0A\00", align 1
@.str.5 = private unnamed_addr constant [8 x i8] c"g = %d\0A\00", align 1
@.str.6 = private unnamed_addr constant [8 x i8] c"h = %d\0A\00", align 1
define i32 @main(){
    ;int a,b,c,d,e,f,g,h;
    %1 = alloca i32, align 4
    %2 = alloca i32, align 4
    %3 = alloca i32, align 4
    %4 = alloca i32, align 4
    %5 = alloca i32, align 4
    %6 = alloca i32, align 4
    %7 = alloca i32, align 4
    %8 = alloca i32, align 4
    store i32 10, i32* %1, align 4
    store i32 3, i32* %2, align 4
    ;c = a == b;
    %9 = load i32, i32* %1, align 4
    %10 = load i32, i32* %2, align 4
    %11 = icmp eq i32 %9, %10
    %12 = zext i1 %11 to i32
    store i32 %12, i32* %3, align 4
    ;d = a > b;
    %13 = load i32, i32* %1, align 4
    %14 = load i32, i32* %2, align 4
    %15 = icmp sgt i32 %13, %14
    %16 = zext i1 %15 to i32
    store i32 %16, i32* %4, align 4
    ;e = a < b;
    %17 = load i32, i32* %1, align 4
    %18 = load i32, i32* %2, align 4
    %19 = icmp slt i32 %17, %18
    %20 = zext i1 %19 to i32
    store i32 %20, i32* %5, align 4
    ;f = a <= b;
    %21 = load i32, i32* %1, align 4
    %22 = load i32, i32* %2, align 4
    %23 = icmp sle i32 %21, %22
    %24 = zext i1 %23 to i32
    store i32 %12, i32* %6, align 4
    ;g = a >= b;
    %25 = load i32, i32* %1, align 4
    %26 = load i32, i32* %2, align 4
    %27 = icmp sge i32 %25, %26
    %28 = zext i1 %27 to i32
    store i32 %28, i32* %7, align 4
    ;h = b != a;
    %29 = load i32, i32* %2, align 4
    %30 = load i32, i32* %1, align 4
    %31 = icmp ne i32 %29, %30
    %32 = zext i1 %31 to i32
    store i32 %32, i32* %8, align 4
    ;输出
    %33 = load i32, i32* %3, align 4
    %34 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.1, i64 0, i64 0), i32 %33)
    %35 = load i32, i32* %4, align 4
    %36 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.2, i64 0, i64 0), i32 %35)
    %37 = load i32, i32* %5, align 4
    %38 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.3, i64 0, i64 0), i32 %37)
    %39 = load i32, i32* %6, align 4
    %40 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.4, i64 0, i64 0), i32 %39)
    %41 = load i32, i32* %7, align 4
    %42 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.5, i64 0, i64 0), i32 %41)
    %43 = load i32, i32* %8, align 4
    %44 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.6, i64 0, i64 0), i32 %43)
    ret i32 0
}