PYTHON ?= python3
PROFILE_SECONDS ?= 5
PROFILE_RUNS ?= 3
VARIANTS ?= c-os,c-o2,c-noinline,native-o2
RESULT_DIR ?=
SYMBOL ?=
RISCV_ELF ?=

.PHONY: all check build profile report inspect test clean

all: check build profile report

check:
	$(PYTHON) run_profiles.py check

build:
	$(PYTHON) run_profiles.py build --variants "$(VARIANTS)"

profile:
	$(PYTHON) run_profiles.py profile \
		--variants "$(VARIANTS)" \
		--seconds "$(PROFILE_SECONDS)" \
		--runs "$(PROFILE_RUNS)" \
		$(if $(strip $(RESULT_DIR)),--output "$(RESULT_DIR)",)

report:
	$(PYTHON) run_profiles.py report \
		$(if $(strip $(RESULT_DIR)),--input "$(RESULT_DIR)",) \
		$(if $(strip $(RISCV_ELF)),--riscv-elf "$(RISCV_ELF)",)

inspect:
	@test -n "$(SYMBOL)" || { echo "ERROR: use SYMBOL=<simbolo>"; exit 2; }
	$(PYTHON) run_profiles.py inspect \
		--symbol "$(SYMBOL)" \
		$(if $(strip $(RESULT_DIR)),--input "$(RESULT_DIR)",) \
		$(if $(strip $(RISCV_ELF)),--riscv-elf "$(RISCV_ELF)",)

test:
	$(PYTHON) -m unittest -v test_analyze_gprof.py

clean:
	$(PYTHON) run_profiles.py clean
