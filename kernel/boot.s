
; Minimal protected mode bootloader (loads kernel and jumps to 32-bit entry)
BITS 16
ORG 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Set up GDT
    lgdt [gdt_desc]

    ; Enter protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to flush prefetch and load CS
    jmp 0x08:protected_mode

; 32-bit code
[BITS 32]
protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; Jump to kernel entry point (start)
    call start

    ; Hang if kernel returns
.hang:
    hlt
    jmp .hang

; GDT (Global Descriptor Table)
gdt_start:
    dq 0x0000000000000000 ; Null descriptor
    dq 0x00cf9a000000ffff ; Code segment
    dq 0x00cf92000000ffff ; Data segment
gdt_end:

gdt_desc:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
