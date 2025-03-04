PLATFORM := $(shell uname -s)
ifneq ($(findstring MINGW,$(PLATFORM)),)
PLATFORM := windows32
USE_WINDRES := true
endif

ifneq ($(findstring MSYS,$(PLATFORM)),)
PLATFORM := windows32
endif

ifeq ($(PLATFORM),windows32)
_ := $(shell chcp 65001)
EXESUFFIX:=.exe
NATIVE_CC = clang -IWindows -Wno-deprecated-declarations --target=x86_64-pc-windows
# To force use of the Unix version instead of the Windows version
MKDIR := $(shell which mkdir)
NULL := NUL
else
EXESUFFIX:=
NATIVE_CC := cc
MKDIR := mkdir
NULL := /dev/null
endif

PB12_COMPRESS := pb12$(EXESUFFIX)

RGBASM  := $(RGBDS)rgbasm
RGBLINK := $(RGBDS)rgblink
RGBGFX  := $(RGBDS)rgbgfx
RGBGFX_FLAGS := $(if $(filter $(shell echo 'println __RGBDS_MAJOR__ || (!__RGBDS_MAJOR__ && __RGBDS_MINOR__ > 5)' | $(RGBASM) -), $$0), -h -u, -Z -u -c embedded)

.PHONY : default
default: clean bootroms vmem

.PHONY : bootroms
bootroms: cgb_boot.bin cgb_boot_fast.bin

%.2bpp: %.png
	-@$(MKDIR) -p $(dir $@)
	$(RGBGFX) $(RGBGFX_FLAGS) -o $@ $<

%.pb12: %.2bpp $(PB12_COMPRESS)
	-@$(MKDIR) -p $(dir $@)
	"$(realpath $(PB12_COMPRESS))" < $< > $@
	
$(PB12_COMPRESS): pb12.c
	-@$(MKDIR) -p $(dir $@)
	$(NATIVE_CC) -std=c99 -Wall -Werror $< -o $@

%.bin: %.asm CGB_logo.pb12
	-@$(MKDIR) -p $(dir $@)
	$(RGBASM) $(RGBASM_FLAGS) -o $@.tmp $<
	$(RGBLINK) -x -o $@ $@.tmp
	@rm $@.tmp

.PHONY : vmem
vmem:
	hexdump -v -e '1/1 "%02X \r\n"' cgb_boot.bin > cgb_boot.mif.vmem
	hexdump -v -e '1/1 "%02X \r\n"' cgb_boot_fast.bin > cgb_boot_fast.mif.vmem

.PHONY : clean
clean:
	rm -f $(PB12_COMPRESS)
	rm -f cgb_boot.bin
	rm -f cgb_boot.mif.vmem
	rm -f cgb_boot_fast.bin
	rm -f cgb_boot_fast.mif.vmem
