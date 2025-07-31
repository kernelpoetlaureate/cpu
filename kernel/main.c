// main.c - Minimal kernel main
#include "cpu.h"

void main() {
    struct cpu_info info;
    cpu_detect(&info);
    // Print CPU vendor string to top left of screen
    char *video = (char*)0xb8000;
    for (int i = 0; i < 12; ++i) {
        video[i*2] = info.vendor[i];
        video[i*2+1] = 0x07; // Light grey on black
    }
    while (1) {}
}
