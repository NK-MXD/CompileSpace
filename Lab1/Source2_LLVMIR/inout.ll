;测试输入与输出
;尽管之后我们可以进行链接,我们还需要包含输出输出的声明
declare i32 @getint()
declare i32 @getch()
declare i32 @getarray(i32*)
declare void @putint(i32)
declare void @putch(i32)
declare void @putarray(i32, i32*)
declare i32 @printf(i8*, ...)
@.str = private unnamed_addr constant [30 x i8] c"\E6\95\B0\E7\BB\84\E4\B8\AD\E5\85\83\E7\B4\A0\E4\B8\AA\E6\95\B0\E4\B8\BA: %d\0A\00", align 1

define i32 @main(){
    ;int a,b,c_n;
    ;int c[3];
    %1 = alloca i32, align 4
    %2 = alloca i32, align 4
    %3 = alloca i32, align 4
    %4 = alloca [3 x i32], align 4
    ;a = getint()
    %5 = call i32 @getint()
    store i32 %5, i32* %1, align 4
    ;b = getch()
    %6 = call i32 @getch()
    store i32 %6, i32* %2, align 4
    ;c_n = getarray(c)
    %7 = getelementptr inbounds [3 x i32], [3 x i32]* %4, i64 0, i64 0
    %8 = call i32 @getarray(i32* %7)
    store i32 %8, i32* %3, align 4
    ;putint(a);
    %9 = load i32, i32* %1, align 4
    call void @putint(i32 %9)
    ;putch(b);
    %10 = load i32, i32* %2, align 4
    call void @putch(i32 %10)
    ;putarray(c_n,c);
    %11 = load i32, i32* %3, align 4
    %12 = getelementptr inbounds [3 x i32], [3 x i32]* %4, i64 0, i64 0
    call void @putarray(i32 %11, i32* %12)
    %13 = load i32, i32* %3, align 4
    %14 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([30 x i8], [30 x i8]* @.str, i64 0, i64 0), i32 %13)
    ret i32 0
}