; start.s - Entry point for kernel (calls main)
BITS 32
SECTION .text
GLOBAL start
extern main
start:
    call main
    cli
.hang:
    hlt
    jmp .hang
