// SPDX-License-Identifier: MIT
package vexiiriscv.execute

import spinal.core._
import spinal.lib._

object KeccakSliced {
  def permutationCycles(blocks: Int): Int = 24 + 25 * blocks
  case class Command() extends Bundle {
    val op = UInt(2 bits) // 0 write, 1 read, 2 permute, 3 clear
    val index = UInt(6 bits)
    val data = Bits(32 bits)
  }
}

/** Fold chi/iota/theta over z slices; rho/pi remains constant global wiring.
  *
  * Initial theta is followed by 24 rho/pi + folded chi/iota/theta phases,
  * omitting theta in the last round. Intermediate round boundaries therefore
  * contain theta of the canonical round result. A parity carry bridges slices.
  *
  * The unreset state bank is scrubbed before any command can be accepted.
  * One transaction at a time; every response is held until consumed. Permute
  * takes 24+25*blocks WORK edges after its acceptance edge. Read responds after
  * acceptance; write/clear after blocks work edges. Non-read responses are 0.
  * Writes reuse the slice shift input, avoiding a third 1,600-bit data path.
  */
case class KeccakSlicedCore(blocks: Int = 8) extends Component {
  require(Set(2, 4, 8).contains(blocks))
  import KeccakF1600._
  val width = 64 / blocks
  val io = new Bundle {
    val cmd = slave Stream(KeccakSliced.Command())
    val rsp = master Stream(Bits(32 bits))
  }

  val Idle = U(0, 3 bits)
  val Scrub = U(1, 3 bits)
  val Theta = U(2, 3 bits)
  val RhoPi = U(3, 3 bits)
  val Fold = U(4, 3 bits)
  val WriteRotate = U(5, 3 bits)
  val phase = Reg(UInt(3 bits)) init 1
  val part = Reg(UInt(log2Up(blocks) bits)) init 0
  val round = Reg(UInt(5 bits)) init 0
  val state = Vec.fill(25)(Reg(Bits(64 bits)))
  val carry = Vec.fill(5)(Reg(Bool()) init False)
  val rcShift = Reg(Bits(64 bits)) init 0
  val writeIndex = Reg(UInt(6 bits)) init 0
  val writeShift = Reg(Bits(32 bits)) init 0
  val clearReply = RegInit(False)
  val responseValid = RegInit(False)
  val responseData = Reg(Bits(32 bits)) init 0
  io.rsp.valid := responseValid
  io.rsp.payload := responseData
  io.cmd.ready := phase === Idle && !responseValid
  when(io.rsp.fire) { responseValid := False }

  def parity(input: Seq[Bits]): Seq[Bits] =
    (0 until 5).map(x => (1 until 5).foldLeft(input(x))((a, y) => a ^ input(x + 5*y)))
  def chi(input: Seq[Bits]): Seq[Bits] = (0 until 25).map { i =>
    val x = i % 5; val y = i / 5
    input(i) ^ ((~input((x+1)%5 + 5*y)) & input((x+2)%5 + 5*y))
  }
  def rol(value: Bits, n: Int): Bits =
    if (n == 0) value else value(63-n downto 0) ## value(63 downto 64-n)

  val constants = Vec(RoundConstants.map(B(_, 64 bits)))
  val rhoPi = Array.fill[Bits](25)(null)
  for (y <- 0 until 5; x <- 0 until 5) {
    val i = x + 5*y
    rhoPi(y + 5*((2*x+3*y)%5)) = rol(state(i), RhoOffsets(i))
  }
  val low = state.map(_(width-1 downto 0)).toSeq
  val chiLow = chi(low)
  val chiIota = chiLow.updated(0, chiLow.head ^ rcShift(width-1 downto 0))
  val thetaInput = low.indices.map(i => (phase === Theta) ? low(i) | chiIota(i))
  val c = parity(thetaInput)
  val d = (0 until 5).map(x => c((x+4)%5) ^ (c((x+1)%5)(width-2 downto 0) ## carry((x+1)%5)))
  val output = thetaInput.indices.map { i =>
    (phase === Fold && round === 23) ? chiIota(i) | (thetaInput(i) ^ d(i%5))
  }
  // Theta's incoming bit0 carry comes from the previous bit63, AFTER chi/iota.
  val boundaryChi = chi(rhoPi.toSeq.map(_(63 downto 63)))
  val boundary = boundaryChi.updated(0, boundaryChi.head ^ constants(round)(63 downto 63))
  val boundaryParity = parity(boundary)
  val initialParity = parity(state.map(_(63 downto 63)).toSeq)

  val readData = Bits(32 bits)
  readData := 0
  when(io.cmd.index < WordCount) {
    val lane = state(io.cmd.index(5 downto 1))
    readData := io.cmd.index(0) ? lane(63 downto 32) | lane(31 downto 0)
  }

  val writeHalf = part.msb === writeIndex(0)
  val shifting = phase === Scrub || phase === WriteRotate || phase === Theta || phase === Fold
  for (i <- 0 until 25) {
    val insertion = Bits(width bits)
    insertion := output(i)
    when(phase === Scrub) { insertion := 0 }
    when(phase === WriteRotate) {
      insertion := low(i)
      when(writeIndex(5 downto 1) === i && writeHalf) {
        insertion := writeShift(width-1 downto 0)
      }
    }
    when(shifting || phase === RhoPi) {
      state(i) := (phase === RhoPi) ? rhoPi(i) | (insertion ## state(i)(63 downto width))
    }
  }

  when(io.cmd.fire) {
    responseData := 0
    switch(io.cmd.op) {
      is(0) {
        phase := WriteRotate; part := 0
        writeIndex := io.cmd.index; writeShift := io.cmd.data
      }
      is(1) { responseValid := True; responseData := readData }
      is(2) {
        phase := Theta; part := 0; round := 0; rcShift := 0
        for (x <- 0 until 5) carry(x) := initialParity(x)(0)
      }
      is(3) {
        phase := Scrub; part := 0; round := 0; rcShift := 0
        writeIndex := 0; writeShift := 0
        clearReply := True
        carry.foreach(_ := False)
      }
    }
  }
  when(phase === Scrub) {
    carry.foreach(_ := False)
    round := 0; rcShift := 0; responseData := 0; writeIndex := 0; writeShift := 0
    when(part === blocks-1) {
      phase := Idle; part := 0
      responseValid := clearReply; clearReply := False
    } otherwise { part := part + 1 }
  }
  when(phase === WriteRotate) {
    when(writeHalf) { writeShift := (writeShift >> width).resized }
    when(part === blocks-1) {
      phase := Idle; part := 0; writeIndex := 0; writeShift := 0
      responseValid := True; responseData := 0
    } otherwise { part := part + 1 }
  }
  when(phase === Theta || phase === Fold) {
    for (x <- 0 until 5) carry(x) := c(x)(width-1)
    when(phase === Fold) { rcShift := (rcShift >> width).resized }
    when(part === blocks-1) {
      part := 0
      when(phase === Fold && round === 23) {
        phase := Idle; responseValid := True; responseData := 0
        round := 0; rcShift := 0; carry.foreach(_ := False)
      } otherwise {
        phase := RhoPi
        when(phase === Fold) { round := round + 1 }
      }
    } otherwise { part := part + 1 }
  }
  when(phase === RhoPi) {
    for (x <- 0 until 5) carry(x) := boundaryParity(x)(0)
    rcShift := constants(round)
    phase := Fold
  }
}
