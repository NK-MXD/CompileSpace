declare i32 @getint()
declare i32 @getch()
declare i32 @getarray(i32*)
declare void @putint(i32)
declare void @putch(i32)
declare void @putarray(i32, i32*)
declare i32 @printf(i8*, ...)

define i32 @main(){
    %1 = alloca i32, align 4
    %2 = alloca i32, align 4
    %3 = alloca i32, align 4
    %4 = alloca [3 x i32], align 4
    %5 = call i32 @getint()
    store i32 %5, i32* %1, align 4
    %6 = call i32 @getch()
    store i32 %6, i32* %2, align 4
    %7 = getelementptr inbounds [3 x i32], [3 x i32]* %4, i64 0, i64 0
    %8 = call i32 @getarray(i32* %7)
    store i32 %8, i32* %3, align 4
    %9 = load i32, i32* %1, align 4
    call void @putint(i32 %9)
    %10 = load i32, i32* %2, align 4
    call void @putch(i32 %10)
    %11 = load i32, i32* %3, align 4
    %12 = getelementptr inbounds [3 x i32], [3 x i32]* %4, i64 0, i64 0
    call void @putarray(i32 %11, i32* %12)
    %13 = load i32, i32* %1, align 4
    call void (i8*, ...) @putf(i8* getelementptr inbounds ([3 x i8], [3 x i8]*@.str, i64 0, i64 0), i32 %13)
    ret i32 0
}

