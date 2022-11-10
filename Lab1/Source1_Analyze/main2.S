	.file	"main2.cpp"
	.text
	.p2align 4
	.globl	_Z9fibonaccii
	.type	_Z9fibonaccii, @function
_Z9fibonaccii:
.LFB0:
	.cfi_startproc
	endbr64
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movl	$1, %eax
	pushq	%rbx
	.cfi_def_cfa_offset 24
	.cfi_offset 3, -24
	leal	-1(%rdi), %ebx
	subq	$8, %rsp
	.cfi_def_cfa_offset 32
	cmpl	$1, %ebx
	jbe	.L1
	xorl	%ebp, %ebp
.L3:
	movl	%ebx, %edi
	subl	$2, %ebx
	call	_Z9fibonaccii
	addl	%eax, %ebp
	cmpl	$1, %ebx
	ja	.L3
	leal	1(%rbp), %eax
.L1:
	addq	$8, %rsp
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE0:
	.size	_Z9fibonaccii, .-_Z9fibonaccii
	.section	.text.startup,"ax",@progbits
	.p2align 4
	.globl	main
	.type	main, @function
main:
.LFB1:
	.cfi_startproc
	endbr64
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
	movl	$-1, %edx
.L13:
	movl	%edx, %edi
	call	_Z9fibonaccii
	subl	$2, %edx
	cmpl	$1, %edx
	ja	.L13
	xorl	%eax, %eax
	addq	$8, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE1:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	 1f - 0f
	.long	 4f - 1f
	.long	 5
0:
	.string	 "GNU"
1:
	.align 8
	.long	 0xc0000002
	.long	 3f - 2f
2:
	.long	 0x3
3:
	.align 8
4:
