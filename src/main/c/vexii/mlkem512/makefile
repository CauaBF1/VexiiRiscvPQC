PROJ_NAME = mlkem512
BENCH_ROUNDS ?= 2
KAT ?= no

# repo root, relative to this makefile (src/main/c/vexii/mlkem512)
ROOT := ../../../../..
MLKEM_NATIVE_DIR := $(ROOT)/external/mlkem-native/mlkem

APP_C_SRCS   := $(wildcard src/*.c)
APP_ASM_SRCS := $(wildcard src/*.S)
MLKEM_NATIVE_C_SRCS := $(MLKEM_NATIVE_DIR)/mlkem_native.c

# KAT=yes builds main_kat.c (byte-exact vector check); otherwise the benchmark main.c.
# Filter keeps exactly one main() in the link.
ifeq ($(KAT),yes)
	APP_C_SRCS := $(filter-out src/main.c,$(APP_C_SRCS))
else
	APP_C_SRCS := $(filter-out src/main_kat.c,$(APP_C_SRCS))
endif

OBJDIR = build
INC    = -I./src -I$(MLKEM_NATIVE_DIR)
LDSCRIPT = ./src/linker.ld

# rv64 bare-metal toolchain (override RISCV_PATH/RISCV_NAME if installed elsewhere)
RISCV_NAME ?= riscv64-unknown-elf
RISCV_PATH ?= /home/borgescaua/opt/riscv-elf-multilib

MABI  := lp64
MARCH := rv64imac_zicsr   # rv64: 'm' for Kyber mul, 'c' matches newlib multilib, zicsr for rdcycle

CFLAGS  += -march=$(MARCH) -mabi=$(MABI) -DNDEBUG -DBENCH_ROUNDS=$(BENCH_ROUNDS)
CFLAGS  += -DMLK_CONFIG_FILE=\"mlkem_native_vexii_config.h\"
CFLAGS  += -g -Os -mcmodel=medany -MD -fstrict-volatile-bitfields -fno-strict-aliasing -ffreestanding
LDFLAGS += -march=$(MARCH) -mabi=$(MABI)
LDFLAGS += -nostdlib -nostartfiles -ffreestanding -mcmodel=medany
LDFLAGS += -Wl,-Bstatic,-T,$(LDSCRIPT),-Map,$(OBJDIR)/$(PROJ_NAME).map,--print-memory-usage
LDLIBS  += -lgcc

ifneq ($(strip $(RISCV_PATH)),)
RISCV_PREFIX := $(RISCV_PATH)/bin/$(RISCV_NAME)
else
RISCV_PREFIX := $(RISCV_NAME)
endif
RISCV_CC      = $(RISCV_PREFIX)-gcc
RISCV_OBJCOPY = $(RISCV_PREFIX)-objcopy
RISCV_OBJDUMP = $(RISCV_PREFIX)-objdump

APP_C_OBJS   := $(patsubst src/%.c,$(OBJDIR)/src/%.o,$(APP_C_SRCS))
APP_ASM_OBJS := $(patsubst src/%.S,$(OBJDIR)/src/%.o,$(APP_ASM_SRCS))
MLKEM_OBJS   := $(patsubst $(MLKEM_NATIVE_DIR)/%.c,$(OBJDIR)/mlkem-native/%.o,$(MLKEM_NATIVE_C_SRCS))
OBJS := $(APP_C_OBJS) $(APP_ASM_OBJS) $(MLKEM_OBJS)

all: $(OBJDIR)/$(PROJ_NAME).elf $(OBJDIR)/$(PROJ_NAME).asm

$(OBJDIR)/$(PROJ_NAME).elf: $(OBJS)
	$(RISCV_CC) $(CFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)

%.asm: %.elf
	$(RISCV_OBJDUMP) -S -d $< > $@

$(OBJDIR)/src/%.o: src/%.c
	@mkdir -p $(dir $@)
	$(RISCV_CC) -c $(CFLAGS) $(INC) -o $@ $<

$(OBJDIR)/src/%.o: src/%.S
	@mkdir -p $(dir $@)
	$(RISCV_CC) -c $(CFLAGS) -o $@ $< -D__ASSEMBLY__=1

$(OBJDIR)/mlkem-native/%.o: $(MLKEM_NATIVE_DIR)/%.c
	@mkdir -p $(dir $@)
	$(RISCV_CC) -c $(CFLAGS) $(INC) -o $@ $<

.PHONY: clean
clean:
	rm -rf $(OBJDIR)

.SECONDARY: $(OBJS)
