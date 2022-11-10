	.arch armv7-a
	.eabi_attribute 28, 1
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 6
	.eabi_attribute 34, 1
	.eabi_attribute 18, 4
	.file	"help.c"
	.text
	.comm	_sysy_start,8,4
	.comm	_sysy_end,8,4
	.comm	_sysy_l1,4096,4
	.comm	_sysy_l2,4096,4
	.comm	_sysy_h,4096,4
	.comm	_sysy_m,4096,4
	.comm	_sysy_s,4096,4
	.comm	_sysy_us,4096,4
	.comm	_sysy_idx,4,4
	.global	initVal
	.section	.rodata
	.align	2
	.type	initVal, %object
	.size	initVal, 4
initVal:
	.word	1
	.global	length
	.data
	.align	2
	.type	length, %object
	.size	length, 4
length:
	.word	3
	.text
	.align	1
	.global	fibonacci
	.arch armv7-a
	.syntax unified
	.thumb
	.thumb_func
	.fpu vfpv3-d16
	.type	fibonacci, %function
fibonacci:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{r4, r7, lr}
	sub	sp, sp, #12
	add	r7, sp, #0
	str	r0, [r7, #4]
	ldr	r3, [r7, #4]
	cmp	r3, #1
	beq	.L2
	ldr	r3, [r7, #4]
	cmp	r3, #2
	bne	.L3
.L2:
	movs	r3, #1
	b	.L4
.L3:
	ldr	r3, [r7, #4]
	subs	r3, r3, #1
	mov	r0, r3
	bl	fibonacci(PLT)
	mov	r4, r0
	ldr	r3, [r7, #4]
	subs	r3, r3, #2
	mov	r0, r3
	bl	fibonacci(PLT)
	mov	r3, r0
	add	r3, r3, r4
.L4:
	mov	r0, r3
	adds	r7, r7, #12
	mov	sp, r7
	@ sp needed
	pop	{r4, r7, pc}
	.size	fibonacci, .-fibonacci
	.section	.rodata
	.align	2
.LC0:
	.ascii	"\012cal = a + b - b*2 + a/3 = %d\012\000"
	.align	2
.LC1:
	.ascii	"log = a > 5 && (b > 10 || a > b) = %d\012\000"
	.align	2
.LC2:
	.ascii	"ral = a >= b || (!a && (a + b) > 20 ) = %d\012\000"
	.text
	.align	1
	.global	main
	.syntax unified
	.thumb
	.thumb_func
	.fpu vfpv3-d16
	.type	main, %function
main:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{r7, lr}
	sub	sp, sp, #24
	add	r7, sp, #0
	bl	getint(PLT)
	str	r0, [r7, #4]
	ldr	r0, [r7, #4]
	bl	fibonacci(PLT)
	str	r0, [r7, #8]
	ldr	r2, [r7, #4]
	ldr	r3, [r7, #8]
	add	r2, r2, r3
	ldr	r3, [r7, #8]
	lsls	r3, r3, #1
	subs	r1, r2, r3
	ldr	r2, [r7, #4]
	movw	r3, #21846
	movt	r3, 21845
	smull	r3, r0, r3, r2
	asrs	r3, r2, #31
	subs	r3, r0, r3
	add	r3, r3, r1
	str	r3, [r7, #12]
	ldr	r3, [r7, #4]
	cmp	r3, #5
	ble	.L6
	ldr	r3, [r7, #8]
	cmp	r3, #10
	bgt	.L7
	ldr	r2, [r7, #4]
	ldr	r3, [r7, #8]
	cmp	r2, r3
	ble	.L6
.L7:
	movs	r3, #1
	b	.L8
.L6:
	movs	r3, #0
.L8:
	str	r3, [r7, #16]
	ldr	r2, [r7, #4]
	ldr	r3, [r7, #8]
	cmp	r2, r3
	bge	.L9
	ldr	r3, [r7, #4]
	cmp	r3, #0
	bne	.L10
	ldr	r2, [r7, #4]
	ldr	r3, [r7, #8]
	add	r3, r3, r2
	cmp	r3, #20
	ble	.L10
.L9:
	movs	r3, #1
	b	.L11
.L10:
	movs	r3, #0
.L11:
	str	r3, [r7, #20]
	ldr	r0, [r7, #8]
	bl	putint(PLT)
	ldr	r1, [r7, #12]
	ldr	r3, .L13
.LPIC0:
	add	r3, pc
	mov	r0, r3
	bl	printf(PLT)
	ldr	r1, [r7, #16]
	ldr	r3, .L13+4
.LPIC1:
	add	r3, pc
	mov	r0, r3
	bl	printf(PLT)
	ldr	r1, [r7, #20]
	ldr	r3, .L13+8
.LPIC2:
	add	r3, pc
	mov	r0, r3
	bl	printf(PLT)
	movs	r3, #0
	mov	r0, r3
	adds	r7, r7, #24
	mov	sp, r7
	@ sp needed
	pop	{r7, pc}
.L14:
	.align	2
.L13:
	.word	.LC0-(.LPIC0+4)
	.word	.LC1-(.LPIC1+4)
	.word	.LC2-(.LPIC2+4)
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0"
	.section	.note.GNU-stack,"",%progbits
