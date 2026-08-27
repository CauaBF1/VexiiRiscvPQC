package vexiiriscv.execute

import spinal.core._
import spinal.core.sim.SpinalSimConfig
import spinal.lib._
import vexiiriscv.{ParamSimple, VexiiRiscv}
import vexiiriscv.riscv.{IntRegFile, RS1, RS2, Riscv}
import vexiiriscv.tester.TestOptions

// Custom instruction `montmul rd, rs1, rs2` = Montgomery modular multiply mod q=3329.
// It computes exactly mlk_montgomery_reduce((int32)int16(rs1) * (int32)int16(rs2)),
// the single hot op behind the whole ML-KEM NTT/invNTT/mulcache (mlk_fqmul).
//
//   prod = a * b                         (int16 x int16 -> int32)
//   t    = (prod[15:0] * QINV)[15:0]     (low 16 bits, reinterpreted signed)
//   r    = (prod - t*q) >> 16            (arithmetic; fits int16)
//
// q and QINV(=q^-1 mod 2^16) are fixed constants -> hardwired. 3 x 16-bit muls,
// one subtract, one shift, fully combinational (1 cycle in Execute(0)).
//
// Encoding (R-type, custom-0 opcode 0x0B, func3=0, func7=1; func7=0 is SimdAdd):
//   0000001----------000-----0001011
object MontMulPlugin {
  val MONTMUL = IntRegFile.TypeR(M"0000001----------000-----0001011")
  val Q = MontgomeryDatapath.Q
  val QINV = MontgomeryDatapath.QINV
}

class MontMulPlugin(val layer : LaneLayer) extends ExecutionUnitElementSimple(layer) {
  val logic = during setup new Logic {
    awaitBuild()

    val wb  = newWriteback(ifp, 0)
    val uop = add(MontMulPlugin.MONTMUL).spec
    uop.addRsSpec(RS1, executeAt = 0)
    uop.addRsSpec(RS2, executeAt = 0)
    uopRetainer.release()

    val process = new el.Execute(id = 0) {
      val a    = up(el(IntRegFile, RS1))(15 downto 0).asSInt                 // int16
      val b    = up(el(IntRegFile, RS2))(15 downto 0).asSInt                 // int16
      val r    = MontgomeryDatapath.multiply(a, b)
      wb.valid := SEL
      wb.payload := r.resize(Riscv.XLEN).asBits                             // sign-extend to XLEN
    }
  }
}

// Reuses the TestBench harness: accepts --load-elf, all microarchitecture flags,
// and reports cycles. Compare healthy core vs healthy+montmul for the honest gain.
object VexiiMontmulSim extends App {
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
  println(s"With Vexiiriscv parm :\n - ${param.getName()}")
  val compiled = simConfig.compile {
    val pa = param.pluginsArea()
    ParamSimple.setPma(pa.plugins)
    VexiiRiscv(pa.plugins)
  }
  testOpt.test(compiled)
}
