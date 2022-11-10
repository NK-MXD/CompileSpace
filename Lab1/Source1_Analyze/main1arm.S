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
	.file	"main1.cpp"
	.text
	.global	p
	.data
	.align	2
	.type	p, %object
	.size	p, 4
p:
	.word	10
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
	.fnstart
.LFB0:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	push	{r7}
	sub	sp, sp, #28
	add	r7, sp, #0
	movs	r3, #0
	str	r3, [r7, #4]
	movs	r3, #1
	str	r3, [r7, #8]
	movs	r3, #1
	str	r3, [r7, #12]
.L3:
	ldr	r2, [r7, #12]
	ldr	r3, [r7, #16]
	cmp	r2, r3
	bge	.L2
	ldr	r3, [r7, #8]
	str	r3, [r7, #20]
	ldr	r2, [r7, #8]
	ldr	r3, [r7, #4]
	add	r3, r3, r2
	str	r3, [r7, #8]
	ldr	r3, [r7, #20]
	str	r3, [r7, #4]
	ldr	r3, [r7, #12]
	adds	r3, r3, #1
	str	r3, [r7, #12]
	b	.L3
.L2:
	movs	r3, #0
	mov	r0, r3
	adds	r7, r7, #28
	mov	sp, r7
	@ sp needed
	ldr	r7, [sp], #4
	bx	lr
	.cantunwind
	.fnend
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0"
	.section	.note.GNU-stack,"",%progbits
