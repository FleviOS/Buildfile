ASM = nasm
QEMU = qemu-system-i386
QEMU_ARGS = -fda 
GITC = git clone
SRC_DIR = ./src

GIT_REPO = https://github.com/FleviOS/FleviBooter-BIOS.git

BOOTLD_RT_DIR = $(SRC_DIR)/boot
OUT_RT_DIR = ./dist
BOOTLD_DIR = $(SRC_DIR)/boot/bios
KRNL_DIR = $(SRC_DIR)/krnl/code
OUT_DIR = ./dist/build
MID_DIR = ./dist/comp
PARTIAL_DIR = ./dist/parts

OS_OUT = $(OUT_DIR)/os.img

$(OS_OUT): $(MID_DIR)/bootloader.bin $(MID_DIR)/kernel.bin
	dd if=/dev/zero of=$(OS_OUT) bs=512 count=2880
	mkfs.fat -F 12 -n FLOSDEV ./dist/build/os.img
	mcopy -i $(OS_OUT) $(MID_DIR)/kernel.bin "::kernel.bin"
	dd if=$(MID_DIR)/bootloader.bin of=$(OS_OUT) bs=512 count=1 conv=notrunc

$(MID_DIR)/kernel.bin: $(KRNL_DIR)/main.asm
	@if [ ! -d "./dist" ] ; then \
		echo "The output directories were not found, we are running 'make setup' to resolve this issue."; \
		$(MAKE) setup; \
	fi
	@$(ASM) $(KRNL_DIR)/main.asm -f bin -o $(MID_DIR)/kernel.bin

$(MID_DIR)/bootloader.bin: $(BOOTLD_DIR)/code/biosstg.asm
	@if [ ! -d "./dist" ] ; then \
		echo "The output directories were not found, we are running 'make setup' to resolve this issue."; \
		$(MAKE) setup; \
	fi
	@$(ASM) $(BOOTLD_DIR)/code/biosstg.asm -f bin -o $(MID_DIR)/bootloader.bin

setup:
	@mkdir -p $(OUT_DIR) $(MID_DIR) $(PARTIAL_DIR)
	@if [ -d "$(BOOTLD_DIR)" ]; then \
		echo "$(BOOTLD_DIR) already exists, skipping git clone."; \
	else \
		$(GITC) $(GIT_REPO) $(BOOTLD_DIR); \
	fi
	@which mkfs.fat > /dev/null 2>&1 || (echo "Installing dosfstools..." && sudo apt update && sudo apt install -y dosfstools)
	@which mcopy > /dev/null 2>&1 || (echo "Installing mtools..." && sudo apt update && sudo apt install -y mtools)
	@echo "All dependencies are installed! 🎉"

run:
	@if [ ! -f "$(OS_OUT)" ]; then \
		echo "Error: Build output '$(OS_OUT)' not found. Running 'make'..."; \
		$(MAKE); \
	fi
	$(QEMU) $(QEMU_ARGS)$(OS_OUT)

resetup:
	rm -rf $(BOOTLD_RT_DIR)/
	rm -rf $(OUT_RT_DIR)/
	$(MAKE) setup

clean:
	rm -rf $(OUT_RT_DIR)/
	$(MAKE) setup

cleanmake : clean
	$(MAKE)