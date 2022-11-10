;测试逻辑运算符
;输出声明
declare i32 @printf(i8*, ...)
@.str.1 = private unnamed_addr constant [8 x i8] c"i = %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [8 x i8] c"j = %d\0A\00", align 1
@.str.3 = private unnamed_addr constant [8 x i8] c"k = %d\0A\00", align 1

define i32 @main(){
    ;int a,b,i,j,k;
    %1 = alloca i32, align 4
    %2 = alloca i32, align 4
    %3 = alloca i32, align 4
    %4 = alloca i32, align 4
    %5 = alloca i32, align 4
    store i32 10, i32* %1, align 4
    store i32 3, i32* %2, align 4
    ;i = a > 2 || b < 2;
    %6 = load i32, i32* %1, align 4
    %7 = icmp sgt i32 %6, 2
    ;先判断 a > 2 是否为true,若为true则最后值为true
    br i1 %7, label %11, label %8 
8:
    %9 = load i32, i32* %2, align 4
    %10 = icmp slt i32 %9, 2
    br label %11
11:
    %12 = phi i1 [ true, %0 ], [ %10, %8 ]
    %13 = zext i1 %12 to i32
    store i32 %13, i32* %3, align 4
    ;j = a >10 && b > 2;
    %14 = load i32, i32* %1, align 4
    %15 = icmp sgt i32 %14, 10
    ;先判断 a > 10 是否为false,若为false则最后值为false
    br i1 %15, label %16, label %19
16:
    %17 = load i32, i32* %2, align 4
    %18 = icmp sgt i32 %17, 2
    br label %19
19:
    %20 = phi i1 [ false, %11 ], [ %18, %16 ]
    %21 = zext i1 %20 to i32
    store i32 %21, i32* %4, align 4
    ;k = !(a>b);
    %22 = load i32, i32* %1, align 4
    %23 = load i32, i32* %2, align 4
    %24 = icmp sgt i32 %22, %23
    ;用xor来表示!
    %25 = xor i1 %24, true
    %26 = zext i1 %25 to i32
    store i32 %26, i32* %5, align 4
    ;输出
    %27 = load i32, i32* %3, align 4
    %28 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.1, i64 0, i64 0), i32 %27)
    %29 = load i32, i32* %4, align 4
    %30 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.2, i64 0, i64 0), i32 %29)
    %31 = load i32, i32* %5, align 4
    %32 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @.str.3, i64 0, i64 0), i32 %31)
    ret i32 0
}