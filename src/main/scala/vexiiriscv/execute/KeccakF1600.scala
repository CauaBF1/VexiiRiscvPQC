// SPDX-License-Identifier: MIT

package vexiiriscv.execute

import spinal.core._

/** Keccak-f[1600] combinational round and iterative state engine.
  *
  * State lanes use the FIPS-202 index x + 5*y. Rotations have constant offsets,
  * so synthesis implements them as wiring rather than a generic barrel shifter.
  */
object KeccakF1600 {
  val LaneCount = 25
  val WordCount = 50
  val RoundCount = 24

  val RoundConstants: Seq[BigInt] = Seq(
    BigInt("0000000000000001", 16), BigInt("0000000000008082", 16),
    BigInt("800000000000808a", 16), BigInt("8000000080008000", 16),
    BigInt("000000000000808b", 16), BigInt("0000000080000001", 16),
    BigInt("8000000080008081", 16), BigInt("8000000000008009", 16),
    BigInt("000000000000008a", 16), BigInt("0000000000000088", 16),
    BigInt("0000000080008009", 16), BigInt("000000008000000a", 16),
    BigInt("000000008000808b", 16), BigInt("800000000000008b", 16),
    BigInt("8000000000008089", 16), BigInt("8000000000008003", 16),
    BigInt("8000000000008002", 16), BigInt("8000000000000080", 16),
    BigInt("000000000000800a", 16), BigInt("800000008000000a", 16),
    BigInt("8000000080008081", 16), BigInt("8000000000008080", 16),
    BigInt("0000000080000001", 16), BigInt("8000000080008008", 16)
  )

  // Indexed as x + 5*y.
  val RhoOffsets: Seq[Int] = Seq(
     0,  1, 62, 28, 27,
    36, 44,  6, 55, 20,
     3, 10, 43, 25, 39,
    41, 45, 15, 21,  8,
    18,  2, 61, 56, 14
  )

  private def rol64(value: Bits, offset: Int): Bits = {
    require(value.getWidth == 64)
    if (offset == 0) value
    else value(63 - offset downto 0) ## value(63 downto 64 - offset)
  }

  case class RoundSteps(theta: Seq[Bits], rhoPi: Seq[Bits], chi: Seq[Bits], iota: Seq[Bits])

  /** Exposes round boundaries so simulation can localize a mismatch. */
  def steps(input: Seq[Bits], roundConstant: Bits): RoundSteps = {
    require(input.length == LaneCount)
    require(input.forall(_.getWidth == 64))
    require(roundConstant.getWidth == 64)

    val parity = (0 until 5).map { x =>
      (1 until 5).foldLeft(input(x))((acc, y) => acc ^ input(x + 5 * y))
    }
    val thetaDelta = (0 until 5).map { x =>
      parity((x + 4) % 5) ^ rol64(parity((x + 1) % 5), 1)
    }
    val afterTheta = (0 until LaneCount).map { index =>
      input(index) ^ thetaDelta(index % 5)
    }

    val afterRhoPi = Array.fill[Bits](LaneCount)(null)
    for (y <- 0 until 5; x <- 0 until 5) {
      val source = x + 5 * y
      val destination = y + 5 * ((2 * x + 3 * y) % 5)
      afterRhoPi(destination) = rol64(afterTheta(source), RhoOffsets(source))
    }

    val afterChi = (0 until LaneCount).map { index =>
      val x = index % 5
      val y = index / 5
      afterRhoPi(index) ^ ((~afterRhoPi((x + 1) % 5 + 5 * y)) & afterRhoPi((x + 2) % 5 + 5 * y))
    }
    val afterIota = afterChi.updated(0, afterChi(0) ^ roundConstant)
    RoundSteps(afterTheta, afterRhoPi.toSeq, afterChi, afterIota)
  }

  /** One complete theta/rho/pi/chi/iota round. */
  def round(input: Seq[Bits], roundConstant: Bits): Seq[Bits] =
    steps(input, roundConstant).iota
}

/** Registered 1,600-bit state with one combinational Keccak round per cycle.
  *
  * The first round is committed on the edge accepting start. The final round is
  * committed on the 24th edge; `done` is asserted during that final cycle.
  */
case class KeccakF1600Core() extends Component {
  import KeccakF1600._

  val io = new Bundle {
    val writeValid = in Bool()
    val writeIndex = in UInt(6 bits)
    val writeData = in Bits(32 bits)
    val readIndex = in UInt(6 bits)
    val readData = out Bits(32 bits)
    val start = in Bool()
    val clear = in Bool()
    val busy = out Bool()
    val done = out Bool()
  }

  val state = Vec.fill(LaneCount)(Reg(Bits(64 bits)) init 0)
  val busy = RegInit(False)
  val roundIndex = Reg(UInt(5 bits)) init 0

  val constants = Vec(RoundConstants.map(value => B(value, 64 bits)))
  val selectedConstant = constants(roundIndex)
  val nextState = KeccakF1600.round(state, selectedConstant)
  val firstState = KeccakF1600.round(state, B(RoundConstants.head, 64 bits))

  io.busy := busy
  io.done := busy && roundIndex === RoundCount - 1

  io.readData := 0
  when(io.readIndex < WordCount) {
    val lane = state(io.readIndex(5 downto 1))
    io.readData := io.readIndex(0) ? lane(63 downto 32) | lane(31 downto 0)
  }

  when(io.clear && !busy) {
    state.foreach(_ := 0)
    roundIndex := 0
  } elsewhen(io.writeValid && !busy && io.writeIndex < WordCount) {
    when(io.writeIndex(0)) {
      state(io.writeIndex(5 downto 1))(63 downto 32) := io.writeData
    } otherwise {
      state(io.writeIndex(5 downto 1))(31 downto 0) := io.writeData
    }
  } elsewhen(io.start && !busy) {
    for (index <- 0 until LaneCount) state(index) := firstState(index)
    roundIndex := 1
    busy := True
  } elsewhen(busy) {
    for (index <- 0 until LaneCount) state(index) := nextState(index)
    when(roundIndex === RoundCount - 1) {
      busy := False
    } otherwise {
      roundIndex := roundIndex + 1
    }
  }
}
