/* linker.ld - Minimal x86-64 kernel linker script */
OUTPUT_FORMAT(elf64-x86-64)
ENTRY(_start)

SECTIONS
{
    /* Place everything at 1MB (0x100000) */
    . = 1M;

    /* Multiboot header must be at the beginning */
    .multiboot : {
        *(.multiboot)
    }

    /* Code section */
    .text : {
        *(.text*)
    }

    /* Read-only data */
    .rodata : {
        *(.rodata*)
    }

    /* Data section */
    .data : {
        *(.data*)
    }

    /* BSS section */
    .bss : {
        *(.bss*)
        *(COMMON)
    }
}
