	.file	"main1.cpp"
	.text
	.globl	p
	.data
	.align 4
	.type	p, @object
	.size	p, 4
p:
	.long	10
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	endbr64
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	$0, -20(%rbp)
	movl	$1, -16(%rbp)
	movl	$1, -12(%rbp)
.L3:
	movl	-12(%rbp), %eax
	cmpl	-8(%rbp), %eax
	jge	.L2
	movl	-16(%rbp), %eax
	movl	%eax, -4(%rbp)
	movl	-20(%rbp), %eax
	addl	%eax, -16(%rbp)
	movl	-4(%rbp), %eax
	movl	%eax, -20(%rbp)
	addl	$1, -12(%rbp)
	jmp	.L3
.L2:
	movl	$0, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
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
