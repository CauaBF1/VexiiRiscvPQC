package vexiiriscv.execute

import org.scalatest.funsuite.AnyFunSuite
import spinal.core._
import spinal.core.sim._

import scala.util.Random

case class KeccakRoundDut() extends Component {
  val io = new Bundle {
    val input = in Vec(Bits(64 bits), KeccakF1600.LaneCount)
    val roundConstant = in Bits(64 bits)
    val theta = out Vec(Bits(64 bits), KeccakF1600.LaneCount)
    val rhoPi = out Vec(Bits(64 bits), KeccakF1600.LaneCount)
    val chi = out Vec(Bits(64 bits), KeccakF1600.LaneCount)
    val iota = out Vec(Bits(64 bits), KeccakF1600.LaneCount)
  }

  val steps = KeccakF1600.steps(io.input, io.roundConstant)
  io.theta := Vec(steps.theta)
  io.rhoPi := Vec(steps.rhoPi)
  io.chi := Vec(steps.chi)
  io.iota := Vec(steps.iota)
}

class KeccakF1600Spec extends AnyFunSuite {
  private val mask = (BigInt(1) << 64) - 1

  private def rol(value: BigInt, amount: Int): BigInt =
    if (amount == 0) value & mask
    else ((value << amount) | (value >> (64 - amount))) & mask

  private case class RefSteps(theta: Seq[BigInt], rhoPi: Seq[BigInt], chi: Seq[BigInt], iota: Seq[BigInt])

  private def referenceSteps(input: Seq[BigInt], rc: BigInt): RefSteps = {
    val parity = (0 until 5).map(x => (0 until 5).map(y => input(x + 5 * y)).reduce(_ ^ _))
    val delta = (0 until 5).map(x => parity((x + 4) % 5) ^ rol(parity((x + 1) % 5), 1))
    val theta = input.indices.map(i => (input(i) ^ delta(i % 5)) & mask)
    val rhoPi = Array.fill[BigInt](25)(0)
    for (y <- 0 until 5; x <- 0 until 5) {
      val source = x + 5 * y
      val destination = y + 5 * ((2 * x + 3 * y) % 5)
      rhoPi(destination) = rol(theta(source), KeccakF1600.RhoOffsets(source))
    }
    val chi = (0 until 25).map { i =>
      val x = i % 5
      val y = i / 5
      (rhoPi(i) ^ ((~rhoPi((x + 1) % 5 + 5 * y)) & rhoPi((x + 2) % 5 + 5 * y))) & mask
    }
    val iota = chi.updated(0, chi(0) ^ rc)
    RefSteps(theta, rhoPi.toSeq, chi, iota)
  }

  private def permute(input: Seq[BigInt]): Seq[BigInt] =
    KeccakF1600.RoundConstants.foldLeft(input) { (state, rc) => referenceSteps(state, rc).iota }

  private val zeroKnownAnswer = Seq(
    "f1258f7940e1dde7", "84d5ccf933c0478a", "d598261ea65aa9ee", "bd1547306f80494d", "8b284e056253d057",
    "ff97a42d7f8e6fd4", "90fee5a0a44647c4", "8c5bda0cd6192e76", "ad30a6f71b19059c", "30935ab7d08ffc64",
    "eb5aa93f2317d635", "a9a6e6260d712103", "81a57c16dbcf555f", "43b831cd0347c826", "01f22f1a11a5569f",
    "05e5635a21d9ae61", "64befef28cc970f2", "613670957bc46611", "b87c5a554fd00ecb", "8c3ee88a1ccf32c8",
    "940c7922ae3a2614", "1841f924a2c509e4", "16f53526e70465c2", "75f644e97f30a13b", "eaf1ff7b5ceca249"
  ).map(BigInt(_, 16))

  test("one-round RTL matches every independently modeled step for 10000 states") {
    SimConfig.withVerilator.compile(KeccakRoundDut()).doSim { dut =>
      val random = new Random(0x4b454343414bL)
      for (sample <- 0 until 10000) {
        val state = Seq.fill(25)(BigInt(64, random))
        val round = sample % 24
        val expected = referenceSteps(state, KeccakF1600.RoundConstants(round))
        for (i <- 0 until 25) dut.io.input(i) #= state(i)
        dut.io.roundConstant #= KeccakF1600.RoundConstants(round)
        sleep(1)
        def check(name: String, got: Vec[Bits], wanted: Seq[BigInt]): Unit =
          for (i <- 0 until 25) assert(got(i).toBigInt == wanted(i), s"$name sample=$sample lane=$i")
        check("theta", dut.io.theta, expected.theta)
        check("rho/pi", dut.io.rhoPi, expected.rhoPi)
        check("chi", dut.io.chi, expected.chi)
        check("iota", dut.io.iota, expected.iota)
      }
    }
  }

  test("iterative core implements protocol, exact latency, clear, and 1000 full permutations") {
    SimConfig.withVerilator.compile(KeccakF1600Core()).doSim { dut =>
      dut.clockDomain.forkStimulus(10)
      dut.io.writeValid #= false
      dut.io.writeIndex #= 0
      dut.io.writeData #= 0
      dut.io.readIndex #= 0
      dut.io.start #= false
      dut.io.clear #= false
      dut.clockDomain.waitSampling(2)

      def writeWord(index: Int, value: BigInt): Unit = {
        dut.io.writeIndex #= index
        dut.io.writeData #= value
        dut.io.writeValid #= true
        dut.clockDomain.waitSampling()
        sleep(1)
        dut.io.writeValid #= false
      }
      def readWord(index: Int): BigInt = {
        dut.io.readIndex #= index
        sleep(1)
        dut.io.readData.toBigInt
      }
      def load(state: Seq[BigInt]): Unit = for (lane <- 0 until 25) {
        writeWord(2 * lane, state(lane) & 0xffffffffL)
        writeWord(2 * lane + 1, (state(lane) >> 32) & 0xffffffffL)
      }
      def readState(): Seq[BigInt] = (0 until 25).map { lane =>
        readWord(2 * lane) | (readWord(2 * lane + 1) << 32)
      }
      def startAndWait(): Unit = {
        dut.io.start #= true
        dut.clockDomain.waitSampling()
        sleep(1)
        dut.io.start #= false
        assert(dut.io.busy.toBoolean)
        for (cycle <- 1 until 23) {
          assert(!dut.io.done.toBoolean, s"done early at cycle $cycle")
          dut.clockDomain.waitSampling()
          sleep(1)
        }
        assert(dut.io.done.toBoolean, "done must mark the 24th execution cycle")
        dut.clockDomain.waitSampling()
        sleep(1)
        assert(!dut.io.busy.toBoolean)
      }

      // Required edge cases and invalid-index behavior.
      writeWord(0, 0x01234567L)
      writeWord(49, 0x89abcdefL)
      writeWord(50, 0xffffffffL)
      assert(readWord(0) == 0x01234567L)
      assert(readWord(49) == 0x89abcdefL)
      assert(readWord(50) == 0)
      dut.io.clear #= true
      dut.clockDomain.waitSampling()
      sleep(1)
      dut.io.clear #= false
      assert(readState().forall(_ == 0))

      val fixed = Seq(
        Seq.fill(25)(BigInt(0)),
        (0 until 25).map(BigInt(_)),
        Seq.fill(25)(mask),
        (0 until 25).map(i => BigInt(1) << ((i * 13) % 64))
      )
      val random = new Random(0x46554c4c4bL)
      val states = fixed ++ Seq.fill(996)(Seq.fill(25)(BigInt(64, random)))
      for ((state, sample) <- states.zipWithIndex) {
        load(state)
        startAndWait()
        val expected = if (sample == 0) zeroKnownAnswer else permute(state)
        assert(readState() == expected, s"full permutation sample=$sample")
      }

      // A second permutation without clearing must consume the previous result.
      val once = readState()
      startAndWait()
      assert(readState() == permute(once))
      dut.io.clear #= true
      dut.clockDomain.waitSampling()
      sleep(1)
      dut.io.clear #= false
      assert(readState().forall(_ == 0))
    }
  }
}
