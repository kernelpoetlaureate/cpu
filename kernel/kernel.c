// kernel.c - Minimal Bare-Metal Kernel for CPU Detection

// ----------------------------------------------------------------------------
// 1. Header for our CPU structure (will be defined in cpu.h)
//    Assuming cpu.h defines 'struct archaic_cpu_info' and 'identify_boot_cpu()'
#include "cpu.h"

// ----------------------------------------------------------------------------
// 2. Simple VGA Text Mode Driver
//    Directly writes characters to video memory at 0xB8000
//    This is how we'll get "output" on the screen in QEMU.

// VGA text mode buffer address
volatile unsigned short* vga_buffer = (volatile unsigned short*)0xB8000;
// Current cursor position
int vga_col = 0;
int vga_row = 0;

// Maximum columns and rows in VGA text mode
#define VGA_COLS 80
#define VGA_ROWS 25

// Function to print a character to the VGA buffer
void print_char(char c) {
    if (c == '\n') {
        vga_col = 0;
        vga_row++;
    } else {
        // Character with light gray foreground, black background
        vga_buffer[vga_row * VGA_COLS + vga_col] = (unsigned short)c | 0x0700;
        vga_col++;
    }

    // Scroll if we hit the end of the screen
    if (vga_col >= VGA_COLS) {
        vga_col = 0;
        vga_row++;
    }
    if (vga_row >= VGA_ROWS) {
        // A real OS would scroll the screen; for minimal, just reset
        // For simplicity, we just stop printing newlines at the bottom
        // A more robust solution would clear the top line and shift
        vga_row = VGA_ROWS - 1; // Keep printing on the last line
    }
}

// Function to print a string to the VGA buffer
void print_string(const char* str) {
    while (*str != '\0') {
        print_char(*str);
        str++;
    }
}

// Function to print a hexadecimal number
void print_hex(unsigned int value) {
    const char* hex_digits = "0123456789ABCDEF";
    int i;
    print_string("0x");
    for (i = 7; i >= 0; i--) { // Print 8 hex digits for a 32-bit int
        print_char(hex_digits[(value >> (i * 4)) & 0xF]);
    }
}

// ----------------------------------------------------------------------------
// 3. Main Kernel Entry Point
//    This function is called by the assembly bootloader.
//    It should never return.

void kernel_main() {
    // Clear the screen with black background and light gray text
    for (int i = 0; i < VGA_COLS * VGA_ROWS; i++) {
        vga_buffer[i] = 0x0700; // Light gray on black, space character
    }
    vga_col = 0;
    vga_row = 0;

    print_string("Minimal Bare-Metal CPU Detector\n");
    print_string("-------------------------------\n");

    // Call our CPU identification function
    // This function (from cpu.c) will fill the global boot_cpu_data struct
    identify_boot_cpu();

    // Display detected CPU information
    print_string("Detected CPU:\n");
    print_string("  Vendor: ");
    // Convert 3 dwords to a string for vendor_id
    char vendor_str[13]; // 12 chars + null terminator
    ((unsigned int*)vendor_str)[0] = boot_cpu_data.vendor_id[0];
    ((unsigned int*)vendor_str)[1] = boot_cpu_data.vendor_id[1];
    ((unsigned int*)vendor_str)[2] = boot_cpu_data.vendor_id[2];
    vendor_str[12] = '\0'; // Null-terminate
    print_string(vendor_str);
    print_string("\n");

    print_string("  Family: ");
    print_hex(boot_cpu_data.family);
    print_string("\n");

    print_string("  Model:  ");
    print_hex(boot_cpu_data.model);
    print_string("\n");

    print_string("  Stepping: ");
    print_hex(boot_cpu_data.stepping);
    print_string("\n");

    print_string("  Features: ");
    print_hex(boot_cpu_data.capabilities_flags);
    print_string("\n");

    print_string("\nCPU detection complete. Halted.\n");

    // Infinite loop to halt the system (as there's no OS to return to)
    for (;;) {
        __asm__ volatile ("hlt"); // Halt instruction to stop CPU execution
    }
}
