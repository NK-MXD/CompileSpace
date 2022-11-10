	.text
	.file	"main3.cpp"
	.globl	_Z9fibonaccii           # -- Begin function _Z9fibonaccii
	.p2align	4, 0x90
	.type	_Z9fibonaccii,@function
_Z9fibonaccii:                          # @_Z9fibonaccii
	.cfi_startproc
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%rbx
	pushq	%rax
	.cfi_offset %rbx, -24
	movl	%edi, -12(%rbp)
	cmpl	$1, -12(%rbp)
	je	.LBB0_2
# %bb.1:
	cmpl	$2, -12(%rbp)
	jne	.LBB0_3
.LBB0_2:
	movl	$1, -16(%rbp)
	jmp	.LBB0_4
.LBB0_3:
	movl	-12(%rbp), %edi
	subl	$1, %edi
	callq	_Z9fibonaccii
	movl	%eax, %ebx
	movl	-12(%rbp), %edi
	subl	$2, %edi
	callq	_Z9fibonaccii
	addl	%eax, %ebx
	movl	%ebx, -16(%rbp)
.LBB0_4:
	movl	-16(%rbp), %eax
	addq	$8, %rsp
	popq	%rbx
	popq	%rbp
	.cfi_def_cfa %rsp, 8
	retq
.Lfunc_end0:
	.size	_Z9fibonaccii, .Lfunc_end0-_Z9fibonaccii
	.cfi_endproc
                                        # -- End function
	.globl	main                    # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	subq	$16, %rsp
	movl	$0, -4(%rbp)
	movl	$1000000, %edi          # imm = 0xF4240
	callq	_Z9fibonaccii
	xorl	%eax, %eax
	addq	$16, %rsp
	popq	%rbp
	.cfi_def_cfa %rsp, 8
	retq
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function
	.ident	"clang version 10.0.0-4ubuntu1 "
	.section	".note.GNU-stack","",@progbits
