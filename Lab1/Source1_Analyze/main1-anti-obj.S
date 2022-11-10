
main1.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	f3 0f 1e fa          	endbr64 
   4:	55                   	push   %rbp
   5:	48 89 e5             	mov    %rsp,%rbp
   8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)
   f:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%rbp)
  16:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%rbp)
  1d:	8b 45 f4             	mov    -0xc(%rbp),%eax
  20:	3b 45 f8             	cmp    -0x8(%rbp),%eax
  23:	7d 18                	jge    3d <main+0x3d>
  25:	8b 45 f0             	mov    -0x10(%rbp),%eax
  28:	89 45 fc             	mov    %eax,-0x4(%rbp)
  2b:	8b 45 ec             	mov    -0x14(%rbp),%eax
  2e:	01 45 f0             	add    %eax,-0x10(%rbp)
  31:	8b 45 fc             	mov    -0x4(%rbp),%eax
  34:	89 45 ec             	mov    %eax,-0x14(%rbp)
  37:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  3b:	eb e0                	jmp    1d <main+0x1d>
  3d:	b8 00 00 00 00       	mov    $0x0,%eax
  42:	5d                   	pop    %rbp
  43:	c3                   	retq   
