# Makefile - Minimal x86-64 Bare-Metal Kernel Build

# Tools
AS = nasm
CC = x86_64-elf-gcc
LD = x86_64-elf-ld
OBJCOPY = x86_64-elf-objcopy
QEMU = qemu-system-x86_64

# Flags
ASFLAGS = -f elf64
CFLAGS = -ffreestanding -mno-red-zone -m64 -nostdlib -nostdinc -fno-builtin -fno-stack-protector -Wall -Wextra
LDFLAGS = -T kernel/linker.ld -nostdlib

# Files
KERNEL_DIR = kernel
BOOT = $(KERNEL_DIR)/boot.s
KERNEL_C = $(KERNEL_DIR)/kernel.c $(KERNEL_DIR)/cpu.c
KERNEL_OBJ = boot.o kernel.o cpu.o
KERNEL_BIN = kernel.bin

all: $(KERNEL_BIN)

boot.o: $(BOOT)
	$(AS) $(ASFLAGS) -o $@ $<

kernel.o: $(KERNEL_DIR)/kernel.c $(KERNEL_DIR)/kernel.h
	$(CC) $(CFLAGS) -c -o $@ $(KERNEL_DIR)/kernel.c

cpu.o: $(KERNEL_DIR)/cpu.c $(KERNEL_DIR)/cpu.h
	$(CC) $(CFLAGS) -c -o $@ $(KERNEL_DIR)/cpu.c

$(KERNEL_BIN): boot.o kernel.o cpu.o $(KERNEL_DIR)/linker.ld
	$(LD) $(LDFLAGS) -o $@ boot.o kernel.o cpu.o

run: $(KERNEL_BIN)
	$(QEMU) -kernel $(KERNEL_BIN)

clean:
	rm -f *.o $(KERNEL_BIN)

.PHONY: all run clean
