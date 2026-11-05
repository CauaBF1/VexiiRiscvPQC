// SPDX-License-Identifier: MIT
package vexiiriscv.execute

import spinal.core._
import vexiiriscv.Global
import vexiiriscv.riscv.{IntRegFile, RS1, RS2, Riscv}

/** Experimental sliced implementation of the existing custom-2 instruction ABI.
  * Every command, including read/write/clear, waits for its retained response.
  */
class KeccakSlicedPlugin(val layer: LaneLayer, val blocks: Int = 8) extends ExecutionUnitElementSimple(layer) {
  import KeccakPlugin._

  val logic = during setup new Logic {
    awaitBuild()
    assert(Global.HART_COUNT.get == 1, "KeccakSlicedPlugin supports exactly one hart")
    val wb = newWriteback(ifp, 0)
    private def command(uop: vexiiriscv.riscv.MicroOp, op: UInt): Unit = {
      val spec = add(uop).decode(OP -> op).spec
      spec.addRsSpec(RS1, executeAt = 0)
      spec.addRsSpec(RS2, executeAt = 0)
      spec.dontFlushFrom(0)
    }
    command(KWRITE, OpWrite); command(KREAD, OpRead)
    command(KPERM, OpPermute); command(KCLEAR, OpClear)
    uopRetainer.release()

    val process = new el.Execute(id = 0) {
      val core = KeccakSlicedCore(blocks)
      val selected = isValid && SEL
      val accepted = selected && isReady && !isCancel
      val commandSent = RegInit(False)
      // An externally frozen instruction can already have issued its command.
      // Retain that fact and the core response until the instruction advances.
      when(isReady) { commandSent := False }
      when(core.io.cmd.fire) { commandSent := True }
      core.io.cmd.valid := selected && !isCancel && !commandSent
      core.io.cmd.op := OP
      core.io.cmd.index := up(el(IntRegFile, RS1))(5 downto 0).asUInt
      core.io.cmd.data := up(el(IntRegFile, RS2))(31 downto 0)
      core.io.rsp.ready := accepted && commandSent
      el.freezeWhen(selected && !isCancel && (!commandSent || !core.io.rsp.valid))
      wb.valid := SEL && OP === OpRead && commandSent && core.io.rsp.valid
      wb.payload := core.io.rsp.payload.resize(Riscv.XLEN)
    }
  }
}
