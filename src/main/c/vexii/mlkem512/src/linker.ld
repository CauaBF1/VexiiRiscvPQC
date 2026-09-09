/* Let the GCC driver's -mabi/-march select elf32 or elf64. */
OUTPUT_ARCH(riscv)
ENTRY(crtStart)

/* VexiiRiscv sim: RAM/reset at 0x80000000, backed by SparseMemory in TestBench. */
MEMORY {
  RAM (rwx): ORIGIN = 0x80000000, LENGTH = 16M
}

_stack_size = DEFINED(_stack_size) ? _stack_size : 64k;
_heap_size  = DEFINED(_heap_size)  ? _heap_size  : 16k;

SECTIONS {
  ._vector ORIGIN(RAM): {
    *crt.o(.start_jump);
    *(.text .text.*);
  } > RAM

  .rodata : {
    *(.rdata)
    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2)
    *(.srodata .srodata.*)
  } > RAM

  .data : {
    . = ALIGN(8);
    PROVIDE(__global_pointer$ = . + 0x800);
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
    *(.sdata .sdata.*)
    *(.gnu.linkonce.s.*)
  } > RAM

  .bss (NOLOAD) : {
    . = ALIGN(8);
    _bss_start = .;
    *(.sbss*)
    *(.gnu.linkonce.sb.*)
    *(.bss .bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(8);
    _bss_end = .;
  } > RAM

  ._user_heap (NOLOAD): {
    . = ALIGN(8);
    PROVIDE(_heap_start = .);
    . = . + _heap_size;
    . = ALIGN(8);
    PROVIDE(_heap_end = .);
  } > RAM

  ._stack (NOLOAD): {
    . = ALIGN(16);
    PROVIDE(_stack_end = .);
    . = . + _stack_size;
    . = ALIGN(16);
    PROVIDE(_stack_start = .);
  } > RAM
}
