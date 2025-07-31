kernel/boot.o: kernel/boot.s
kernel/main.o: kernel/main.c
kernel.bin: kernel/boot.o kernel/main.o kernel/linker.ld
# Makefile for minimal x86 kernel (bootable with QEMU)

ASM=nasm
CC=gcc
LD=ld
CFLAGS=-m32 -ffreestanding -fno-pic -fno-stack-protector -nostdlib -nostartfiles -nodefaultlibs
LDFLAGS=-T kernel/linker.ld -nostdlib -m elf_i386 --oformat binary

all: os-image.bin

kernel/boot.bin: kernel/boot.s
	$(ASM) -f bin $< -o $@

kernel/main.o: kernel/main.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel/start.o: kernel/start.s
	$(ASM) -f elf32 $< -o $@

kernel/cpu.o: kernel/cpu.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel/kernel.elf: kernel/start.o kernel/main.o kernel/cpu.o kernel/linker.ld
	$(LD) $(LDFLAGS) kernel/start.o kernel/main.o kernel/cpu.o -o $@

os-image.bin: kernel/boot.bin kernel/kernel.elf
	cat kernel/boot.bin kernel/kernel.elf > $@

run: os-image.bin
	qemu-system-i386 -drive format=raw,file=os-image.bin

clean:
	rm -f kernel/*.o kernel/*.bin kernel/*.elf os-image.bin
