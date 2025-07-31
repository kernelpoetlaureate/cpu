# Minimal CPU Project

This project implements a minimal CPU struct for bare metal environments. The hardware is intended to be provided by QEMU for testing and development purposes.

## Project Goals
- Minimal implementation: Only essential features are included.
- Bare metal only: No OS dependencies, runs directly on hardware or QEMU.
- Written for learning and experimentation.

## Usage
- QEMU is required to emulate the hardware environment.
- Build and run the project according to your toolchain and QEMU setup.

### WSL2/Linux Support
This project is compatible with WSL2 and native Linux environments. To get started:

1. Install [WSL2](https://docs.microsoft.com/en-us/windows/wsl/) and a Linux distribution (e.g., Ubuntu).
2. Install required packages in your WSL2/Linux shell:
   ```sh
   sudo apt update
   sudo apt install build-essential qemu-system-x86
   ```
   (QEMU is required for emulation. On other platforms, install QEMU from your package manager or from https://www.qemu.org/download/)
3. Build and run the project using your preferred toolchain and QEMU.
4. All development and testing can be done from within the WSL2/Linux terminal.

## Notes
- This project is intentionally minimal and may lack many features found in full CPU implementations.
- Contributions and suggestions are welcome.
