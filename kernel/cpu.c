// cpu.c - Minimal bare metal CPU feature detection (x86)
#include "cpu.h"

void cpu_detect(struct cpu_info* info) {
    unsigned int eax, ebx, ecx, edx;
    // Get vendor string
    __asm__ __volatile__ (
        "cpuid"
        : "=a"(eax), "=b"(ebx), "=c"(ecx), "=d"(edx)
        : "a"(0)
    );
    ((uint32_t*)info->vendor)[0] = ebx;
    ((uint32_t*)info->vendor)[1] = edx;
    ((uint32_t*)info->vendor)[2] = ecx;
    info->vendor[12] = 0;
    // Get feature bits
    __asm__ __volatile__ (
        "cpuid"
        : "=a"(eax), "=b"(ebx), "=c"(ecx), "=d"(edx)
        : "a"(1)
    );
    info->features_edx = edx;
    info->features_ecx = ecx;
}
