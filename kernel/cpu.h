// cpu.h - Defines the minimal CPU information structure and prototypes

#ifndef _CPU_H
#define _CPU_H

// --- 1. Basic CPU Feature Flags ---
// These are simplified and correspond to common CPUID feature bits.
// In a real kernel, there are hundreds of these!
#define CPU_FEATURE_FPU       (1 << 0)  // Bit 0: Floating Point Unit
#define CPU_FEATURE_VME       (1 << 1)  // Bit 1: Virtual 8086 Mode Extensions
#define CPU_FEATURE_PSE       (1 << 3)  // Bit 3: Page Size Extensions (4MB pages)
#define CPU_FEATURE_TSC       (1 << 4)  // Bit 4: Time Stamp Counter
#define CPU_FEATURE_MSR       (1 << 5)  // Bit 5: Model Specific Registers
#define CPU_FEATURE_PAE       (1 << 6)  // Bit 6: Physical Address Extension (36-bit addresses)
#define CPU_FEATURE_APIC      (1 << 9)  // Bit 9: APIC on-chip
#define CPU_FEATURE_SSE       (1 << 25) // Bit 25: SSE (Streaming SIMD Extensions)
#define CPU_FEATURE_SSE2      (1 << 26) // Bit 26: SSE2

// For 64-bit specific features (from extended CPUID leaves, not original features)
#define CPU_FEATURE_LM        (1 << 30) // Bit 30: Long Mode (64-bit capable) - from EAX=0x80000001 EDX

// --- 2. Archaic CPU Information Structure ---
// Stores the basic CPU identification details obtained from CPUID.
struct archaic_cpu_info {
    // Vendor ID (e.g., "GenuineIntel", "AuthenticAMD")
    // Raw 3 DWORDS as returned by CPUID EAX=0 (EBX, EDX, ECX)
    unsigned int vendor_id[3];

    // CPU Family, Model, Stepping (from CPUID EAX=1)
    unsigned int family;
    unsigned int model;
    unsigned int stepping;

    // A bitmask of supported features (using the CPU_FEATURE_X defines above)
    unsigned int capabilities_flags;
};

// --- 3. Global Instance of CPU Info ---
// This will be populated by identify_boot_cpu() and used by kernel_main().
// 'extern' means it's defined elsewhere (in cpu.c in this case).
extern struct archaic_cpu_info boot_cpu_data;

// --- 4. Function Prototype for CPU Detection ---
// This function will perform the CPUID calls and populate boot_cpu_data.
void identify_boot_cpu(void);

#endif // _CPU_H
