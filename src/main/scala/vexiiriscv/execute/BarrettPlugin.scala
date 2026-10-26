// SPDX-License-Identifier: MIT
package vexiiriscv.execute

import spinal.core._
import vexiiriscv.riscv.{IntRegFile, RS1, RS2, Riscv}

/** barrett rd, rs1: centered signed reduction of rs1[15:0] modulo 3329.
  * custom-0 (0x0b), funct3=0, funct7=3. RS2 and the upper RS1 bits are ignored.
  * Stateless combinational arithmetic in Execute(0), sign-extended to XLEN.
  */
object BarrettPlugin {
  val BARRETT = IntRegFile.TypeR(M"0000011----------000-----0001011")
}

class BarrettPlugin(val layer: LaneLayer) extends ExecutionUnitElementSimple(layer) {
  val logic = during setup new Logic {
    awaitBuild()
    val wb = newWriteback(ifp, 0)
    val uop = add(BarrettPlugin.BARRETT).spec
    uop.addRsSpec(RS1, executeAt = 0)
    uop.addRsSpec(RS2, executeAt = 0) // R-type convention, even though unused.
    uopRetainer.release()

    val process = new el.Execute(id = 0) {
      val a = up(el(IntRegFile, RS1))(15 downto 0).asSInt
      val result = BarrettDatapath.reduce(a)
      wb.valid := SEL
      wb.payload := result.resize(Riscv.XLEN).asBits
    }
  }
}
