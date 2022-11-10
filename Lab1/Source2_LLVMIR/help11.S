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
	.section	.rodata
	.align	2
.LC0:
	.ascii	"\346\225\260\347\273\204\344\270\255\345\205\203\347"
	.ascii	"\264\240\344\270\252\346\225\260\344\270\272: %d\012"
	.ascii	"\000"
	.text
	.align	1
	.global	main
	.arch armv7-a
	.syntax unified
	.thumb
	.thumb_func
	.fpu vfpv3-d16
	.type	main, %function
main:
	@ args = 0, pretend = 0, frame = 32
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{r7, lr}
	sub	sp, sp, #32
	add	r7, sp, #0
	ldr	r2, .L4
.LPIC1:
	add	r2, pc
	ldr	r3, .L4+4
	ldr	r3, [r2, r3]
	ldr	r3, [r3]
	str	r3, [r7, #28]
	mov	r3,#0
	bl	getint(PLT)
	str	r0, [r7, #4]
	bl	getch(PLT)
	str	r0, [r7, #8]
	add	r3, r7, #16
	mov	r0, r3
	bl	getarray(PLT)
	str	r0, [r7, #12]
	ldr	r0, [r7, #4]
	bl	putint(PLT)
	ldr	r0, [r7, #8]
	bl	putch(PLT)
	add	r3, r7, #16
	mov	r1, r3
	ldr	r0, [r7, #12]
	bl	putarray(PLT)
	ldr	r1, [r7, #12]
	ldr	r3, .L4+8
.LPIC0:
	add	r3, pc
	mov	r0, r3
	bl	printf(PLT)
	movs	r3, #0
	ldr	r1, .L4+12
.LPIC2:
	add	r1, pc
	ldr	r2, .L4+4
	ldr	r2, [r1, r2]
	ldr	r1, [r2]
	ldr	r2, [r7, #28]
	eors	r1, r2, r1
	mov	r2, #0
	beq	.L3
	bl	__stack_chk_fail(PLT)
.L3:
	mov	r0, r3
	adds	r7, r7, #32
	mov	sp, r7
	@ sp needed
	pop	{r7, pc}
.L5:
	.align	2
.L4:
	.word	_GLOBAL_OFFSET_TABLE_-(.LPIC1+4)
	.word	__stack_chk_guard(GOT)
	.word	.LC0-(.LPIC0+4)
	.word	_GLOBAL_OFFSET_TABLE_-(.LPIC2+4)
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0"
	.section	.note.GNU-stack,"",%progbits
