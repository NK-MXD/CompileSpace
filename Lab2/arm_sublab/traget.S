    .arch armv7-a
@ 数据段
@ 全局变量及常量的声明  
@ const int initVal = 1;
    .data
    .global	initVal 
    @这里我们常量声明用只读数据表示和变量做区分
	.section	.rodata 
	.align	2
    @我们将符号initVal的类型设置为object
	.type	initVal, %object
    @指定initVal变量为4个字节
	.size	initVal, 4
initVal:
	.word	1
@ int length = 3;
    .data
	.global	length
	.align	2
	.type	length, %object
	.size	length, 4
length:
	.word	3

    .text
    @字符串同样声明为只读数据
    .section	.rodata 
	.align	2
_str0:
	.ascii	"\012cal = a + b - b*2 + a/3 = %d\012\000"
	.align	2
_str1:
	.ascii	"log = a > 5 && (b > 10 || a > b) = %d\012\000"
	.align	2
_str2:
	.ascii	"ral = a >= b || (!a && (a + b) > 20 ) = %d\012\000"

@ 代码段
@ fibonacci函数
@ int fibonacci(int n)
    .text
    .global fibonacci
    @ 定义类型为函数
    .type	fibonacci, %function
fibonacci: 
    @ 从左到右压栈r4 r7 lr 保存寄存器上下文
    push	{r4, r7, lr}
    sub     sp, sp, #12 
    @ 传入实参n    
    add	r7, sp, #0
	str	r0, [r7, #4]
	ldr	r3, [r7, #4]
    @ n == 1
	cmp	r3, #1
	beq	.L1
    @ n == 2
	ldr	r3, [r7, #4]
	cmp	r3, #2
	bne	.L2
.L1:
    @ 常量initVal替换为对应的值1
	movs	r3, #1
	b	.L3
.L2:
    @ fibonacci(n-1)
	ldr	r3, [r7, #4]
	subs	r3, r3, #1
    @ 传入参数
	mov	r0, r3
	bl	fibonacci
    @ 函数返回值直接存入r0
	mov	r4, r0
    @ fibonacci(n-1)
	ldr	r3, [r7, #4]
	subs	r3, r3, #2
	mov	r0, r3
	bl	fibonacci
	mov	r3, r0
    @ 计算得到函数返回值
	add	r3, r3, r4
.L3:
	mov	r0, r3
	adds	r7, r7, #12
	mov	sp, r7
	@ 恢复上下文
	pop	{r4, r7, pc} 

@ 代码段
@ main函数
@ int main() 
    .text
    .global main
    .type main , %function
main:
    @ 保存寄存器上下文
    push	{r7, lr}
	sub	sp, sp, #24
	add	r7, sp, #0
    @ 调用getint()
	bl	getint
    @ a = getint();
	str	r0, [r7, #4]
	ldr	r0, [r7, #4]
    @ b = fibonacci(a);
	bl	fibonacci
	str	r0, [r7, #8]
	ldr	r2, [r7, #4]
	ldr	r3, [r7, #8]
    @ cal = a + b - b*2 + a/3 ;
    @ 计算a = a + b;
	add	r2, r2, r3
	ldr	r3, [r7, #8]
    @ b = b << 1
	lsls	r3, r3, #1
    @ r1 = a - b;
	subs	r1, r2, r3
	ldr	r2, [r7, #4]
    mov r3,#0
    b .CMPDIV
    @ 整数除法
.INTDIV:
    sub r2, r2, #3
    add r3, r3, #1
.CMPDIV:
    cmp r2, #0
    bgt .INTDIV
    @ cal = r1 + r3
	add	r3, r3, r1
	str	r3, [r7, #12]
    @ 计算 log = a > 5 && (b > 10 || a > b);
    @ 先判断 a > 5 短路原理
	ldr	r3, [r7, #4]
	cmp	r3, #5
	ble	L5  @ ble小于等于
    @ a > 5为True 判断 b > 10
	ldr	r3, [r7, #8]
	cmp	r3, #10
	bgt	.L6
    @ a > b
	ldr	r2, [r7, #4]
	ldr	r3, [r7, #8]
	cmp	r2, r3
	ble	L5
.L6: @ True
	movs	r3, #1
	b	.L7
L5: @ False
	movs	r3, #0
.L7:
	str	r3, [r7, #16]
    @ ral = a >= b || (!a && (a + b) > 20 ) ;
	ldr	r2, [r7, #4]
	ldr	r3, [r7, #8]
    @ a >= b
	cmp	r2, r3
	bge	.L8
    @ !a
	ldr	r3, [r7, #4]
	cmp	r3, #0
	bne	.L9
    @ (a + b) > 20 
	ldr	r2, [r7, #4]
	ldr	r3, [r7, #8]
	add	r3, r3, r2
	cmp	r3, #20
	ble	.L9
.L8: @ True
	movs	r3, #1
	b	.L10
.L9: @ False
	movs	r3, #0
.L10:
	str	r3, [r7, #20]
	ldr	r0, [r7, #8]
    @ putint(b);
	bl	putint
    
    @ return 0
    movs	r3, #0
	mov	r0, r3
	adds	r7, r7, #24
	mov	sp, r7
	@ sp needed
	pop	{r7, pc}

_bridge:
	.word	_str0
	.word	_str1
	.word	_str2
	.section	.note.GNU-stack,"",%progbits

