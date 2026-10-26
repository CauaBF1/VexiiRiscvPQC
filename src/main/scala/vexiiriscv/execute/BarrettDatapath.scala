// SPDX-License-Identifier: MIT
package vexiiriscv.execute

import spinal.core._

/** Centered reduction modulo 3329, bit-exact to mlk_barrett_reduce(int16_t).
  * Products and bias are signed and fit in 32 bits over the complete S16 domain.
  * The quotient is -10..10; its product with Q must not be truncated to S16.
  */
object BarrettDatapath {
  val Q = 3329
  val Magic = 20159

  def reduce(a: SInt): SInt = {
    require(a.getWidth == 16, s"Barrett expects 16 bits, got ${a.getWidth}")
    val product = (a * S(Magic, 16 bits)).resize(32 bits)
    val rounded = product + S(1 << 25, 32 bits)
    // Slicing the signed high bits implements the arithmetic shift by 26.
    val quotient = rounded.asBits(31 downto 26).asSInt
    val correction = (quotient * S(Q, 16 bits)).resize(32 bits)
    (a.resize(32 bits) - correction).resize(16 bits)
  }
}
