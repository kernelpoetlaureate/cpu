/* linker.ld - Linker script for minimal kernel */
OUTPUT_FORMAT("binary")
ENTRY(start)
SECTIONS {
    . = 0x7C00;
    .text : { *(.text) }
    .data : { *(.data) }
    .bss  : { *(.bss)  }
}
