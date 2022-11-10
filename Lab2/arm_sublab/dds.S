.text 
.global main
main:
    push {r0,r1,r2,lr} @push
    mov r1, #3
    adr r0, hello
    bl printf
    pop {r0,r1,r2,pc}
hello: 
    .asciz "hello %d \n"
