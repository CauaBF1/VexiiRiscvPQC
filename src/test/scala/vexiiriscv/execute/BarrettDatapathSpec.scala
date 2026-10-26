package vexiiriscv.execute

import org.scalatest.funsuite.AnyFunSuite
import spinal.core._
import spinal.core.sim._

case class BarrettDatapathDut() extends Component {
  val io = new Bundle {
    val input = in SInt(16 bits)
    val result = out SInt(16 bits)
    val result32 = out SInt(32 bits)
    val result64 = out SInt(64 bits)
  }
  val reduced = BarrettDatapath.reduce(io.input)
  io.result := reduced
  io.result32 := reduced.resize(32 bits)
  io.result64 := reduced.resize(64 bits)
}

class BarrettDatapathSpec extends AnyFunSuite {
  test("all 65536 inputs match independent centered modulo and the C formula") {
    SimConfig.withVerilator.compile(BarrettDatapathDut()).doSim { dut =>
      for (a <- -32768 to 32767) {
        val canonical = Math.floorMod(a, 3329)
        val expected = if (canonical > 1664) canonical - 3329 else canonical
        val quotient = (20159L * a + (1L << 25)) >> 26
        val formula = a - quotient * 3329
        assert(formula == expected)
        dut.io.input #= a
        sleep(1)
        assert(dut.io.result.toInt == expected, s"barrett($a)")
        assert(dut.io.result32.toInt == expected, s"RV32 sign extension($a)")
        assert(dut.io.result64.toBigInt == BigInt(expected), s"RV64 sign extension($a)")
        assert(expected >= -1664 && expected <= 1664)
        assert(Math.floorMod(a - expected, 3329) == 0)
      }
    }
  }
}
