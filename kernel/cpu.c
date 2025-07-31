// cpu.c - Implementation of CPU identification logic

#include "cpu.h" // Include our CPU info structure definition

// Define the global instance of the CPU info structure.
// This is where 'boot_cpu_data' is actually allocated in memory.
struct archaic_cpu_info boot_cpu_data;

// Function to execute CPUID instruction
// Inputs:  EAX register value for the CPUID leaf
// Outputs: EAX, EBX, ECX, EDX register values after CPUID
static void cpuid(unsigned int leaf, unsigned int *eax, unsigned int *ebx, unsigned int *ecx, unsigned int *edx) {
    __asm__ volatile (
        "cpuid"
        : "=a" (*eax), "=b" (*ebx), "=c" (*ecx), "=d" (*edx)
        : "a" (leaf)
    );
}

// Function to identify the CPU and populate the global boot_cpu_data structure
void identify_boot_cpu(void) {
    unsigned int eax, ebx, ecx, edx;

    // --- 1. Get Vendor ID and Max CPUID Leaf ---
    cpuid(0x00000000, &eax, &ebx, &ecx, &edx);
    boot_cpu_data.vendor_id[0] = ebx;
    boot_cpu_data.vendor_id[1] = edx;
    boot_cpu_data.vendor_id[2] = ecx;
    unsigned int max_basic_cpuid_leaf = eax;

    // --- 2. Get Processor Info and Feature Bits (CPUID Leaf 0x00000001) ---
    if (max_basic_cpuid_leaf >= 0x00000001) {
        cpuid(0x00000001, &eax, &ebx, &ecx, &edx);
        boot_cpu_data.family = (eax >> 8) & 0xF;
        boot_cpu_data.model = (eax >> 4) & 0xF;
        boot_cpu_data.stepping = eax & 0xF;
        if (boot_cpu_data.family == 0xF) {
            boot_cpu_data.family += ((eax >> 20) & 0xFF);
        }
        if (boot_cpu_data.family == 0x6 || boot_cpu_data.family == 0xF) {
            boot_cpu_data.model += ((eax >> 16) & 0xF) << 4;
        }
        boot_cpu_data.capabilities_flags = 0;
        if (edx & (1 << 0))  boot_cpu_data.capabilities_flags |= CPU_FEATURE_FPU;
        if (edx & (1 << 1))  boot_cpu_data.capabilities_flags |= CPU_FEATURE_VME;
        if (edx & (1 << 3))  boot_cpu_data.capabilities_flags |= CPU_FEATURE_PSE;
        if (edx & (1 << 4))  boot_cpu_data.capabilities_flags |= CPU_FEATURE_TSC;
        if (edx & (1 << 5))  boot_cpu_data.capabilities_flags |= CPU_FEATURE_MSR;
        if (edx & (1 << 6))  boot_cpu_data.capabilities_flags |= CPU_FEATURE_PAE;
        if (edx & (1 << 9))  boot_cpu_data.capabilities_flags |= CPU_FEATURE_APIC;
        if (edx & (1 << 25)) boot_cpu_data.capabilities_flags |= CPU_FEATURE_SSE;
        if (edx & (1 << 26)) boot_cpu_data.capabilities_flags |= CPU_FEATURE_SSE2;
        // ECX features can be added here if needed
    }

    // --- 3. Get Extended Processor Info and Feature Bits (CPUID Leaf 0x80000001) ---
    cpuid(0x80000000, &eax, &ebx, &ecx, &edx);
    unsigned int max_extended_cpuid_leaf = eax;
    if (max_extended_cpuid_leaf >= 0x80000001) {
        cpuid(0x80000001, &eax, &ebx, &ecx, &edx);
        if (edx & (1 << 29)) boot_cpu_data.capabilities_flags |= (1 << 29); // AMD EPP (Extended Page Table)
        if (edx & (1 << 30)) boot_cpu_data.capabilities_flags |= CPU_FEATURE_LM; // Long Mode (64-bit support)
    }
}
