; boot.s - Minimal x86-64 Bare-Metal Bootloader
; This file is assembled using NASM (or GAS with AT&T syntax adjustments)

; --- 1. Multiboot Header ---
; This is a special header that tells a bootloader (like GRUB, or in our case, QEMU)
; how to load our kernel. QEMU can often boot without it, but it's good practice.
; The bootloader expects this at the very beginning of the kernel image.
section .multiboot
    align 4
    dd 0x1BADB002             ; Multiboot magic number
    dd 0x0                    ; Flags (0 means no features requested)
    dd -(0x1BADB002 + 0x0)    ; Checksum (magic + flags + checksum = 0)

; --- 2. Code Section ---
; Our actual executable code.
section .text
    ; Global symbol for the entry point. This is where QEMU will start execution.
    global _start

_start:
    ; --- 2.1. Initial Setup (Real Mode - 16-bit) ---
    ; CPU starts in 16-bit Real Mode. We need to transition to Protected Mode (32-bit)
    ; and then to Long Mode (64-bit).

    ; Disable interrupts (important for kernel initialisation)
    cli

    ; Clear direction flag (for string operations)
    cld

    ; Setup a very basic stack for initial operations.
    ; This stack is temporary, as we'll set up a proper one in 64-bit mode.
    mov sp, 0x7C00 ; Place stack pointer at end of traditional boot sector memory

    ; --- 2.2. Enable A20 Line ---
    ; The A20 line needs to be enabled to access memory above 1MB.
    ; This is a legacy mechanism from the IBM PC AT, still relevant in early boot.
    ; This specific code sequence might vary by BIOS/firmware, but this is common.
    ; It interacts with the keyboard controller.
    in al, 0x92       ; Read from Port 0x92 (PS/2 controller data port)
    or al, 0x02       ; Set A20 bit
    out 0x92, al      ; Write back to enable A20

    ; --- 2.3. Enable Protected Mode (Transition to 32-bit) ---
    ; Load the Global Descriptor Table (GDT). The GDT defines memory segments.
    lgdt [gdt_ptr]

    ; Enable the Protected Mode bit in CR0 register
    mov eax, cr0
    or eax, 0x1       ; Set PE (Protected Mode Enable) bit
    mov cr0, eax

    ; Far jump to flush the instruction pipeline and reload CS (Code Segment)
    ; with the new protected mode segment.
    jmp CODE_SEG:protected_mode_start

; --- 3. Protected Mode (32-bit) ---
bits 32
protected_mode_start:
    ; Set up segment registers for Protected Mode.
    ; All segments now point to the flat 4GB memory space.
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax ; Set stack segment (though we'll switch to 64-bit stack soon)

    ; --- 3.1. Enable PAE (Physical Address Extension) ---
    ; PAE is required for Long Mode (64-bit). It enables 36-bit physical addressing.
    mov ecx, 0xC0000080 ; EFER MSR (Extended Feature Enable Register)
    rdmsr               ; Read EFER into EDX:EAX
    or eax, 0x100       ; Set LME (Long Mode Enable) bit
    wrmsr               ; Write back to EFER

    ; --- 3.2. Setup Paging for Long Mode ---
    ; Long Mode requires paging to be enabled.
    ; We'll create a very simple 4-level paging structure (PML4, PDPT, PD, PT)
    ; to map the first 4GB of physical memory to virtual memory.

    ; Zero out PML4 (Page Map Level 4) table
    ; It's crucial that these page tables are 4KB aligned.
    ; We place them after our code.
    mov edi, pml4_table
    xor eax, eax
    mov ecx, 512 / 4 ; 512 entries, 4 bytes each
    rep stosd        ; Fill with zeros

    ; Populate PML4 entry to point to PDPT (Page Directory Pointer Table)
    mov dword [pml4_table], pdpt_table | 0x3 ; Present, Read/Write

    ; Zero out PDPT table
    mov edi, pdpt_table
    xor eax, eax
    mov ecx, 512 / 4
    rep stosd

    ; Populate PDPT entry to point to PD (Page Directory) table
    ; This maps the first 1GB with 1GB pages (huge pages)
    mov dword [pdpt_table], pd_table | 0x3 ; Present, Read/Write

    ; Zero out PD table
    mov edi, pd_table
    xor eax, eax
    mov ecx, 512 / 4
    rep stosd

    ; Populate PD entries to map 1GB of physical memory starting from 0.
    ; Each entry maps 2MB. We create 512 entries for 1GB (512 * 2MB = 1GB).
    ; We map 0MB - 1GB, as that's often where the kernel code resides.
    mov ecx, 0
    mov ebx, 0
.map_2mb_pages:
    mov dword [pd_table + ebx*8], ecx | 0x83 ; Present, Read/Write, Huge Page
    add ecx, 0x200000 ; Increment physical address by 2MB
    inc ebx
    cmp ebx, 512      ; Map 512 entries (for 1GB)
    jne .map_2mb_pages

    ; Load PML4 physical address into CR3 (Page-level Base Register)
    mov eax, pml4_table
    mov cr3, eax

    ; Enable PAE (already done, but re-confirm) and PGE (Page Global Enable, optional but good) in CR4
    mov eax, cr4
    or eax, 0x20       ; Set PAE bit
    or eax, 0x80       ; Set PGE bit
    mov cr4, eax

    ; Enable Long Mode in EFER MSR (already done, but re-confirm)
    mov ecx, 0xC0000080 ; EFER MSR
    rdmsr
    or eax, 0x100      ; Set LME (Long Mode Enable) bit
    wrmsr

    ; Enable Paging in CR0
    mov eax, cr0
    or eax, 0x80000000 ; Set PG (Paging Enable) bit
    mov cr0, eax

    ; --- 3.3. Far jump to Long Mode (64-bit) ---
    ; This jump is necessary to flush the instruction pipeline and reload CS
    ; with the new 64-bit segment descriptor.
    jmp CODE_SEG_64:long_mode_start

; --- 4. Long Mode (64-bit) ---
bits 64
long_mode_start:
    ; Set up stack for 64-bit C code.
    ; We'll put the stack at a high address, e.g., 0x90000 (after the 0x80000 mark where we expect our kernel)
    ; This assumes our kernel is small enough not to overlap it, and is within the mapped 1GB.
    mov rsp, 0x90000

    ; Call the C kernel_main function.
    ; The linker will resolve this symbol.
    call kernel_main

    ; If kernel_main returns (it shouldn't in this minimal example), halt the system.
    cli
    hlt

; --- 5. Global Descriptor Table (GDT) ---
; The GDT defines segments for Protected and Long Mode.
; It describes memory regions to the CPU (base, limit, access rights).
section .data
    align 8
gdt_start:
    ; Null Descriptor (required by architecture)
    dq 0

    ; Code Segment Descriptor (for Protected Mode, 32-bit flat)
    ; Base = 0, Limit = 0xFFFFF (4GB), Flags: Present, DPL=0, Type=Code (Execute/Read), Granularity=4KB
    CODE_SEG equ $ - gdt_start
    dq 0x00CF9A000000FFFF ; Segment Descriptor Word 1 + 2 (High & Low)

    ; Data Segment Descriptor (for Protected Mode, 32-bit flat)
    ; Base = 0, Limit = 0xFFFFF (4GB), Flags: Present, DPL=0, Type=Data (Read/Write), Granularity=4KB
    DATA_SEG equ $ - gdt_start
    dq 0x00CF92000000FFFF ; Segment Descriptor Word 1 + 2 (High & Low)

    ; Code Segment Descriptor (for Long Mode, 64-bit)
    ; Base = 0, Limit = 0 (ignored in 64-bit flat mode), Flags: Present, DPL=0, Type=Code (Execute/Read), Long Mode
    CODE_SEG_64 equ $ - gdt_start
    dq 0x00209A0000000000 ; Long Mode Code Segment (L bit set in flags)

gdt_end:

gdt_ptr:
    dw gdt_end - gdt_start - 1 ; GDT Limit (size - 1)
    dd gdt_start               ; GDT Base Address (offset)

; --- 6. Page Tables ---
; These must be 4KB aligned. Placed after the code/data.
; 'resb' reserves bytes.
section .bss
    align 4096
pml4_table:
    resb 4096 ; 4KB for PML4

    align 4096
pdpt_table:
    resb 4096 ; 4KB for Page Directory Pointer Table

    align 4096
pd_table:
    resb 4096 ; 4KB for Page Directory

; We don't need a PT (Page Table) for 2MB huge pages (which we're using for simplicity)
; If we were mapping 4KB pages, we'd need another level here.
