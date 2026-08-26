PROJ_NAME = mlkem512
BENCH_ROUNDS ?= 2
KAT ?= no
# PROFILE=yes: per-component (Keccak vs NTT) cycle accounting via -DMLK_PROFILE.
# Inert otherwise (macros expand to statement-shaped no-ops and do not alter
# the executable code; ELF debug metadata may still differ between source trees).
PROFILE ?= no

ifeq ($(KAT),yes)
ifeq ($(PROFILE),yes)
$(error PROFILE=yes is supported only by the benchmark main.c; use KAT=yes PROFILE=no)
endif
endif

# repo root, relative to this makefile (src/main/c/vexii/mlkem512)
ROOT := ../../../../..
MLKEM_NATIVE_DIR := $(ROOT)/external/mlkem-native/mlkem
# The mlkem-native submodule is pinned at the clean upstream commit; our edits
# (montmul .insn hook + profiling brackets) live in this versioned patch. Run
# `make prep` once after `git clone --recursive` to apply it. Without it, the
# build still works with stock mlkem-native (macros are inert / hooks absent).
MLKEM_NATIVE_ROOT := $(ROOT)/external/mlkem-native
# absolute: `git -C DIR apply FILE` resolves FILE relative to DIR, not to cwd.
MLKEM_PATCH       := $(abspath $(ROOT)/external/mlkem-native.patch)

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
# rv64: 'm' for Kyber mul, 'c' matches newlib multilib, zicsr for rdcycle.
# Overridable so the accel experiments can pass e.g. rv64imac_zba_zbb_zicsr.
MARCH ?= rv64imac_zicsr
# Optimization level, overridable (baseline -Os; accel runs test -O2/-O3).
OPT   ?= -Os

CFLAGS  += -march=$(MARCH) -mabi=$(MABI) -DNDEBUG -DBENCH_ROUNDS=$(BENCH_ROUNDS)
CFLAGS  += -DMLK_CONFIG_FILE=\"mlkem_native_vexii_config.h\"
CFLAGS  += -g $(OPT) -mcmodel=medany -MD -fstrict-volatile-bitfields -fno-strict-aliasing -ffreestanding
ifeq ($(PROFILE),yes)
CFLAGS  += -DMLK_PROFILE
endif
# CFLAGS_EXTRA: pass extra defines without editing the makefile, e.g.
# CFLAGS_EXTRA=-DMLK_USE_MONTMUL to route mlk_fqmul through the montmul instruction.
CFLAGS  += $(CFLAGS_EXTRA)
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

.PHONY: prep
prep:
	@if git -C $(MLKEM_NATIVE_ROOT) apply --reverse --check $(MLKEM_PATCH) 2>/dev/null; then \
	  echo "mlkem-native patch already applied"; \
	elif git -C $(MLKEM_NATIVE_ROOT) apply --check $(MLKEM_PATCH) 2>/dev/null; then \
	  git -C $(MLKEM_NATIVE_ROOT) apply $(MLKEM_PATCH) && echo "mlkem-native patch applied"; \
	else \
	  echo "ERROR: $(MLKEM_PATCH) does not apply cleanly (submodule at wrong commit?)"; exit 1; \
	fi

.PHONY: unprep
unprep:
	@git -C $(MLKEM_NATIVE_ROOT) apply --reverse --check $(MLKEM_PATCH) 2>/dev/null \
	  && git -C $(MLKEM_NATIVE_ROOT) apply --reverse $(MLKEM_PATCH) && echo "mlkem-native patch reverted" \
	  || echo "mlkem-native patch not applied (nothing to revert)"

.PHONY: clean
clean:
	rm -rf $(OBJDIR)

.SECONDARY: $(OBJS)
