package vexiiriscv.execute

import org.scalatest.funsuite.AnyFunSuite
import spinal.core._
import spinal.core.sim._

import scala.util.Random

case class MontgomeryDatapathDut() extends Component {
  val io = new Bundle {
    val mulA = in SInt(16 bits)
    val mulB = in SInt(16 bits)
    val redA = in SInt(32 bits)
    val mulResult = out SInt(16 bits)
    val redResult = out SInt(16 bits)
  }

  io.mulResult := MontgomeryDatapath.multiply(io.mulA, io.mulB)
  io.redResult := MontgomeryDatapath.reduce(io.redA)
}

class MontgomeryDatapathSpec extends AnyFunSuite {
  private val q = MontgomeryDatapath.Q
  private val qInv = MontgomeryDatapath.QINV

  private def signed16(value: Int): Int = {
    val low = value & 0xffff
    if (low >= 0x8000) low - 0x10000 else low
  }

  private def montgomeryReduceRtl(value: Int): Int = {
    val inverted = ((value & 0xffff).toLong * qInv & 0xffffL).toInt
    val t = signed16(inverted)
    val wrappedDifference = (value.toLong - t.toLong * q).toInt
    wrappedDifference >> 16
  }

  private def montgomeryMultiplyRtl(a: Int, b: Int): Int =
    montgomeryReduceRtl(a * b)

  test("generated Montgomery datapath matches the independent bit-vector model") {
    SimConfig.withVerilator.compile(MontgomeryDatapathDut()).doSim { dut =>
      val int16Edges = Seq(-32768, -3329, -1665, -1, 0, 1, 1664, 3329, 32767)
      val int32Edges = Seq(
        Int.MinValue, Int.MinValue + 1, -2038398975, -109084672, -1, 0, 1,
        109084672, 2038398974, 0x7fff8000, Int.MaxValue
      )

      def checkMultiply(a: Int, b: Int): Unit = {
        dut.io.mulA #= a
        dut.io.mulB #= b
        sleep(1)
        assert(dut.io.mulResult.toInt == montgomeryMultiplyRtl(a, b), s"montmul($a, $b)")
      }

      def checkReduce(a: Int): Unit = {
        dut.io.redA #= a
        sleep(1)
        assert(dut.io.redResult.toInt == montgomeryReduceRtl(a), s"montred($a)")
      }

      for (a <- int16Edges; b <- int16Edges) checkMultiply(a, b)
      int32Edges.foreach(checkReduce)

      val random = new Random(0x4d4c4b454dL)
      for (_ <- 0 until 20000) {
        checkMultiply(random.nextInt(1 << 16) - 32768, random.nextInt(1 << 16) - 32768)
        checkReduce(random.nextInt())
      }
    }
  }
}
