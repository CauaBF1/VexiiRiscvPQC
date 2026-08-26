package vexiiriscv.execute

import spinal.core._

/** Shared combinational Montgomery arithmetic used by the custom instructions.
  *
  * All widths are explicit so the generated RTL keeps the same two's-complement
  * wrap and slicing semantics as the original in-plugin implementations.
  */
object MontgomeryDatapath {
  val Q = 3329
  val QINV = 62209

  def reduce(a: SInt): SInt = {
    require(a.getWidth == 32, s"Montgomery reduction expects 32 bits, got ${a.getWidth}")
    val t = (a.asBits(15 downto 0).asUInt * U(QINV, 16 bits))(15 downto 0).asSInt
    val difference = (a - (t * S(Q, 16 bits)).resize(32 bits)).resize(32 bits)
    difference.asBits(31 downto 16).asSInt
  }

  def multiply(a: SInt, b: SInt): SInt = {
    require(a.getWidth == 16, s"Montgomery multiply lhs expects 16 bits, got ${a.getWidth}")
    require(b.getWidth == 16, s"Montgomery multiply rhs expects 16 bits, got ${b.getWidth}")
    reduce((a * b).resize(32 bits))
  }
}
