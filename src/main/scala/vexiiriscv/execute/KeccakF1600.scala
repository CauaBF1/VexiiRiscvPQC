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
  def permutationCycles(compact: Boolean): Int = RoundCount * (if (compact) 6 else 1)

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

  /** Constant rotations and permutation remain wires in both architectures. */
  def thetaRhoPi(input: Seq[Bits]): (Seq[Bits], Seq[Bits]) = {
    require(input.length == LaneCount)
    require(input.forall(_.getWidth == 64))

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

    (afterTheta, afterRhoPi.toSeq)
  }

  /** A single shared five-lane chi datapath; input lanes must be from one row. */
  def chiRow(input: Seq[Bits]): Seq[Bits] = {
    require(input.length == 5 && input.forall(_.getWidth == 64))
    (0 until 5).map(x => input(x) ^ ((~input((x + 1) % 5)) & input((x + 2) % 5)))
  }

  /** Exposes round boundaries so simulation can localize a mismatch. */
  def steps(input: Seq[Bits], roundConstant: Bits): RoundSteps = {
    require(roundConstant.getWidth == 64)
    val (afterTheta, afterRhoPi) = thetaRhoPi(input)
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

/** One 1,600-bit bank. Full uses 24 edges; compact uses 144 edges, including
  * the accepting start edge. Compact writes theta/rho/pi to the same bank,
  * then commits one independent chi row per edge through a shared datapath.
  * `done` marks the cycle that commits the final state, before that edge.
  */
case class KeccakF1600Core(compact: Boolean = false) extends Component {
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
  io.busy := busy

  io.readData := 0
  when(io.readIndex < WordCount) {
    val lane = state(io.readIndex(5 downto 1))
    io.readData := io.readIndex(0) ? lane(63 downto 32) | lane(31 downto 0)
  }

  val clearAccepted = !busy && io.clear
  val validWrite = io.writeValid && io.writeIndex < WordCount
  val writeAccepted = !busy && !io.clear && validWrite
  // A valid write blocks start for every word, not just its destination.
  val startAccepted = !busy && !io.clear && !validWrite && io.start
  val roundActive = busy || startAccepted
  val idleData = clearAccepted ? B(0, 32 bits) | io.writeData

  if (compact) {
    val phase = Reg(UInt(3 bits)) init 0
    val thetaActive = startAccepted || (busy && phase === 0)
    val afterRhoPi = thetaRhoPi(state)._2
    val rowHits = (0 until 5).map(y => busy && phase === y + 1)
    // These five mutually exclusive enables already drive the row writes.
    // Reuse them for a masked-OR read rather than a binary-index mux tree.
    val row = (0 until 5).map { x =>
      (0 until 5).map(y => rowHits(y) ? state(x + 5 * y) | B(0, 64 bits)).reduce(_ | _)
    }
    val chi = chiRow(row)
    // Iota applies only to the first row, and only its first lane.
    val rc = rowHits.head ? constants(roundIndex) | B(0, 64 bits)
    val chiIota = chi.updated(0, chi(0) ^ rc)
    // Select write/clear versus chi once on the shared 320-bit bus. Selecting
    // it again after each lane's theta mux would replicate 1,600 mux bits.
    val sharedData = chiIota.map(lane => busy ? lane | (idleData ## idleData))

    io.done := busy && roundIndex === RoundCount - 1 && phase === 5
    for (word <- 0 until WordCount) {
      val lane = word / 2
      val lo = (word % 2) * 32
      val chiHit = rowHits(lane / 5)
      val writeHit = writeAccepted && io.writeIndex === word
      when(thetaActive || chiHit || clearAccepted || writeHit) {
        state(lane)(lo + 31 downto lo) := thetaActive ?
          afterRhoPi(lane)(lo + 31 downto lo) | sharedData(lane % 5)(lo + 31 downto lo)
      }
    }
    when(clearAccepted) {
      roundIndex := 0
      phase := 0
    } elsewhen(startAccepted) {
      roundIndex := 0
      phase := 1
      busy := True
    } elsewhen(busy) {
      when(phase === 5) {
        phase := 0
        when(roundIndex === RoundCount - 1) {
          busy := False
        } otherwise {
          roundIndex := roundIndex + 1
        }
      } otherwise {
        phase := phase + 1
      }
    }
  } else {
    // E2a baseline: the accepting edge commits the entire first round.
    val selectedConstant = busy ? constants(roundIndex) | B(RoundConstants.head, 64 bits)
    val nextState = KeccakF1600.round(state, selectedConstant)
    io.done := busy && roundIndex === RoundCount - 1
    for (word <- 0 until WordCount) {
      val writeHit = writeAccepted && io.writeIndex === word
      val lane = word / 2
      val lo = (word % 2) * 32
      when(roundActive || clearAccepted || writeHit) {
        state(lane)(lo + 31 downto lo) :=
          roundActive ? nextState(lane)(lo + 31 downto lo) | idleData
      }
    }
    when(clearAccepted) {
      roundIndex := 0
    } elsewhen(roundActive) {
      when(!busy) {
        roundIndex := 1
        busy := True
      } elsewhen(roundIndex === RoundCount - 1) {
        busy := False
      } otherwise {
        roundIndex := roundIndex + 1
      }
    }
  }
}
