// SPDX-License-Identifier: MIT

package vexiiriscv.execute

import spinal.core._
import spinal.lib.misc.pipeline._
import vexiiriscv.Global
import vexiiriscv.riscv.{IntRegFile, RS1, RS2, Riscv}

/** Stateful Keccak-f[1600] instruction interface on custom-2 (opcode 0x5b).
  *
  * funct7 is zero for every command; funct3 selects KWRITE/KREAD/KPERM/KCLEAR.
  */
object KeccakPlugin {
  val KWRITE = IntRegFile.TypeR(M"0000000----------000-----1011011")
  val KREAD  = IntRegFile.TypeR(M"0000000----------001-----1011011")
  val KPERM  = IntRegFile.TypeR(M"0000000----------010-----1011011")
  val KCLEAR = IntRegFile.TypeR(M"0000000----------011-----1011011")

  val OP = Payload(UInt(2 bits))
  val OpWrite = U(0, 2 bits)
  val OpRead = U(1, 2 bits)
  val OpPermute = U(2, 2 bits)
  val OpClear = U(3, 2 bits)
}

class KeccakPlugin(val layer: LaneLayer) extends ExecutionUnitElementSimple(layer) {
  import KeccakPlugin._

  val logic = during setup new Logic {
    awaitBuild()
    assert(Global.HART_COUNT.get == 1, "KeccakPlugin contains one shared state and supports exactly one hart")

    val wb = newWriteback(ifp, 0)

    private def addCommand(microOp: vexiiriscv.riscv.MicroOp, op: UInt) = {
      val spec = add(microOp).decode(OP -> op).spec
      spec.addRsSpec(RS1, executeAt = 0)
      spec.addRsSpec(RS2, executeAt = 0)
      // Once accepted in Execute(0), a stateful command must not be flushed.
      spec.dontFlushFrom(0)
      spec
    }

    addCommand(KWRITE, OpWrite)
    addCommand(KREAD, OpRead)
    addCommand(KPERM, OpPermute)
    addCommand(KCLEAR, OpClear)
    uopRetainer.release()

    val process = new el.Execute(id = 0) {
      val core = KeccakF1600Core()
      val selected = isValid && SEL
      val accepted = selected && isReady && !isCancel
      val commandSent = RegInit(False) setWhen(core.io.start) clearWhen(isReady)

      core.io.writeIndex := up(el(IntRegFile, RS1))(5 downto 0).asUInt
      core.io.writeData := up(el(IntRegFile, RS2))(31 downto 0)
      core.io.readIndex := up(el(IntRegFile, RS1))(5 downto 0).asUInt
      core.io.writeValid := accepted && OP === OpWrite
      core.io.clear := accepted && OP === OpClear
      core.io.start := selected && !isCancel && OP === OpPermute && !commandSent && !core.io.busy

      // done is asserted in the cycle which commits round 23. Releasing the
      // instruction here gives exactly 24 occupied execute cycles.
      el.freezeWhen(selected && OP === OpPermute && !core.io.done)

      wb.valid := SEL && OP === OpRead
      wb.payload := core.io.readData.resize(Riscv.XLEN)
    }
  }
}
