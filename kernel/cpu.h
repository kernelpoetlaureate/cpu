// cpu.h - Minimal bare metal CPU info struct for x86
#ifndef CPU_H
#define CPU_H

#include <stdint.h>

struct cpu_info {
    char vendor[13]; // 12 chars + null terminator
    uint32_t features_edx;
    uint32_t features_ecx;
};

void cpu_detect(struct cpu_info* info);

#endif // CPU_H
