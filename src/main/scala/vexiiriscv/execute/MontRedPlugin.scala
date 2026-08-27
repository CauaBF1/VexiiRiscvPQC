package vexiiriscv.execute

import spinal.core._
import spinal.core.sim.SpinalSimConfig
import spinal.lib._
import vexiiriscv.{ParamSimple, VexiiRiscv}
import vexiiriscv.riscv.{IntRegFile, RS1, RS2, Riscv}
import vexiiriscv.tester.TestOptions

// Custom instruction `montred rd, rs1` = Montgomery reduction of a full int32.
// It computes exactly mlk_montgomery_reduce((int32)rs1) -- the reduction HALF of
// montmul, without the initial 16x16 multiply (the input is already the int32).
// Hooks the ML-KEM basemul (mlk_polyvec_basemul_acc_montgomery_cached_c), the one
// call-site that accumulates products in int32 and reduces directly (not via fqmul).
//
//   a = int32(rs1)                       (rs1[31:0], sign-extended in the 64-bit reg)
//   t = (a[15:0] * QINV)[15:0]           (low 16 bits, reinterpreted signed)
//   r = (a - t*q) >> 16                  (arithmetic; fits int16)
//
// rs2 is unused. q and QINV are fixed constants -> hardwired. 1 x 16-bit mul, one
// subtract, one shift, fully combinational (1 cycle in Execute(0)).
//
// Encoding (R-type, custom-0 opcode 0x0B, func3=0, func7=2; func7=1 is montmul, 0 SimdAdd):
//   0000010----------000-----0001011
object MontRedPlugin {
  val MONTRED = IntRegFile.TypeR(M"0000010----------000-----0001011")
  val Q = MontgomeryDatapath.Q
  val QINV = MontgomeryDatapath.QINV
}

class MontRedPlugin(val layer : LaneLayer) extends ExecutionUnitElementSimple(layer) {
  val logic = during setup new Logic {
    awaitBuild()

    val wb  = newWriteback(ifp, 0)
    val uop = add(MontRedPlugin.MONTRED).spec
    uop.addRsSpec(RS1, executeAt = 0)
    uop.addRsSpec(RS2, executeAt = 0)   // R-type requires RS2 spec even though unused
    uopRetainer.release()

    val process = new el.Execute(id = 0) {
      val a = up(el(IntRegFile, RS1))(31 downto 0).asSInt                    // int32
      val r = MontgomeryDatapath.reduce(a)
      wb.valid := SEL
      wb.payload := r.resize(Riscv.XLEN).asBits                             // sign-extend to XLEN
    }
  }
}

// Injects BOTH montmul and montred so one simulated core serves montmul-only,
// montred-only and both (which instruction is emitted is decided by the C macros
// -DMLK_USE_MONTMUL / -DMLK_USE_MONTRED). Reuses the TestBench harness (--load-elf,
// all microarchitecture flags, cycle report).
object VexiiMontSim extends App {
  val param = new ParamSimple()
  val testOpt = new TestOptions()

  val genConfig = SpinalConfig()
  genConfig.includeSimulation

  val simConfig = SpinalSimConfig()
  simConfig.withFstWave
  simConfig.withTestFolder
  simConfig.withConfig(genConfig)

  assert(new scopt.OptionParser[Unit]("VexiiRiscv") {
    help("help").text("prints this usage text")
    testOpt.addOptions(this)
    param.addOptions(this)
  }.parse(args, ()).nonEmpty)

  param.withMontMul = true
  param.withMontRed = true
  println(s"With Vexiiriscv parm :\n - ${param.getName()}")
  val compiled = simConfig.compile {
    val pa = param.pluginsArea()
    ParamSimple.setPma(pa.plugins)
    VexiiRiscv(pa.plugins)
  }
  testOpt.test(compiled)
}
