/* RV32/RV64 bare-metal startup for the VexiiRiscv simulation testbench.
 * Terminates by landing on the global `pass`/`fail` symbols, which the
 * TestBench watches (commit PC == symbol -> simSuccess/simFailure). */
.global crtStart
.global main
.global pass
.global fail

    .section .start_jump,"ax",@progbits
crtStart:
  j crtInit

.section .text

crtInit:
  .option push
  .option norelax
  la gp, __global_pointer$
  .option pop
  la sp, _stack_start

bss_init:
  la a0, _bss_start
  la a1, _bss_end
bss_loop:
  beq a0, a1, bss_done
#if __riscv_xlen == 64
  sd zero, 0(a0)          /* _bss_start/_bss_end are 8-aligned by linker.ld */
  addi a0, a0, 8
#else
  sw zero, 0(a0)
  addi a0, a0, 4
#endif
  j bss_loop
bss_done:

  call main
  bnez a0, fail           /* main returns non-zero -> failure */

.align 2
pass:
  j pass
.align 2
fail:
  j fail
