package vexiiriscv.execute

import org.scalatest.funsuite.AnyFunSuite
import spinal.core._
import spinal.core.sim._
import scala.sys.process._
import scala.util.Random

object KeccakSlicedGenerate extends App {
  require(args.length == 2, "usage: KeccakSlicedGenerate <directory> <blocks:2|4|8>")
  SpinalConfig(targetDirectory = args(0)).generateVerilog(KeccakSlicedCore(args(1).toInt))
}

class KeccakSlicedSpec extends AnyFunSuite {
  // Numerical oracle is the independent full-lane Python reference, including
  // its fixed zero KAT. No DUT round logic/constants are used to derive vectors.
  private lazy val vectors = {
    val script = """
import sys,random
sys.path.insert(0,'src/test/python')
import keccak_ref as k
assert k.permute([0]*25)==list(k.ZERO_KNOWN_ANSWER)
r=random.Random(0x534c49434544)
states=[[0]*25,list(range(25)),[(1<<64)-1]*25]
states += [k.permute(states[-1])]
states += [[1<<bit if i==lane else 0 for i in range(25)] for lane in (0,4,12,24) for bit in (0,7,15,31,32,63)]
states += [[r.getrandbits(64) for _ in range(25)] for _ in range(1000)]
for n,a in enumerate(states):
 b=k.permute(a); fields=[a,b]
 if n<3:
  fields += [k.round_steps(a,0)['theta']]
  s=a
  for j,rc in enumerate(k.ROUND_CONSTANTS):
   s=k.round_steps(s,rc)['iota']
   fields += [s if j==23 else k.round_steps(s,0)['theta']]
 print('|'.join(','.join(format(x,'016x') for x in f) for f in fields))
"""
    Process(Seq("python3", "-c", script)).!!.trim.split("\n").map { line =>
      line.split("\\|").map(_.split(",").map(BigInt(_, 16)).toSeq).toSeq
    }.toSeq
  }

  for (blocks <- Seq(2, 4, 8)) test(s"sliced Nb=$blocks equivalence, boundaries, latency, backpressure and reset") {
    SimConfig.withVerilator.compile {
      val core = KeccakSlicedCore(blocks)
      core.state.foreach(_.simPublic())
      core.phase.simPublic(); core.part.simPublic(); core.round.simPublic()
      core.carry.foreach(_.simPublic()); core.rcShift.simPublic()
      core.writeIndex.simPublic(); core.writeShift.simPublic()
      core
    }.doSim { dut =>
      SimTimeout(20000000)
      val random = new Random(0x425053L + blocks)
      dut.clockDomain.forkStimulus(10)
      dut.io.cmd.valid #= false
      dut.io.cmd.op #= 0; dut.io.cmd.index #= 0; dut.io.cmd.data #= 0
      dut.io.rsp.ready #= false
      def tick(n: Int = 1): Unit = for (_ <- 0 until n) { dut.clockDomain.waitRisingEdge(); sleep(1) }
      def assertZero(): Unit = {
        assert(dut.state.forall(_.toBigInt == 0))
        assert(dut.carry.forall(!_.toBoolean))
        assert(dut.rcShift.toBigInt == 0)
        assert(dut.writeShift.toBigInt == 0 && dut.writeIndex.toInt == 0)
        assert(dut.round.toInt == 0 && dut.part.toInt == 0)
      }
      def reset(): Unit = {
        dut.io.cmd.valid #= false; dut.io.rsp.ready #= false
        dut.clockDomain.assertReset(); tick(2); dut.clockDomain.deassertReset()
        sleep(1)
        assert(!dut.io.cmd.ready.toBoolean)
        tick(blocks)
        assert(dut.io.cmd.ready.toBoolean && !dut.io.rsp.valid.toBoolean)
        assertZero()
      }
      dut.clockDomain.waitSampling(2) // finish forkStimulus's initial reset first
      reset()

      def accept(op: Int, index: Int = 0, data: BigInt = 0): Unit = {
        assert(dut.io.cmd.ready.toBoolean, s"not ready: phase=${dut.phase.toInt}")
        dut.io.cmd.op #= op; dut.io.cmd.index #= index; dut.io.cmd.data #= data
        dut.io.cmd.valid #= true; tick(); dut.io.cmd.valid #= false
      }
      def finish(op: Int, hold: Int = 0): BigInt = {
        var edges = 0
        if (op != 1) {
          dut.io.cmd.valid #= true; dut.io.cmd.op #= 0
          dut.io.cmd.index #= 0; dut.io.cmd.data #= 0xdeadbeefL
        }
        while (!dut.io.rsp.valid.toBoolean) {
          assert(!dut.io.cmd.ready.toBoolean)
          tick(); edges += 1; assert(edges <= 224)
        }
        assert(edges == (if (op == 2) KeccakSliced.permutationCycles(blocks) else if (op == 1) 0 else blocks), s"op=$op edges=$edges")
        val result = dut.io.rsp.payload.toBigInt
        if (op != 1) assert(result == 0)
        val snapshot = dut.state.map(_.toBigInt).toSeq
        // A pending conflicting command must not be accepted while rsp stalls.
        dut.io.cmd.op #= 3; dut.io.cmd.index #= 0; dut.io.cmd.data #= 0xffffffffL
        dut.io.cmd.valid #= true
        for (_ <- 0 until hold) {
          assert(!dut.io.cmd.ready.toBoolean); tick()
          assert(dut.io.rsp.valid.toBoolean && dut.io.rsp.payload.toBigInt == result)
          assert(dut.state.map(_.toBigInt).toSeq == snapshot)
        }
        dut.io.cmd.valid #= false
        dut.io.rsp.ready #= true; tick(); dut.io.rsp.ready #= false
        assert(!dut.io.rsp.valid.toBoolean && dut.io.cmd.ready.toBoolean)
        result
      }
      def command(op: Int, index: Int = 0, data: BigInt = 0, hold: Int = 0): BigInt = {
        accept(op, index, data); finish(op, hold)
      }
      def load(a: Seq[BigInt]): Unit = for (i <- 0 until 50) {
        command(0, i, (a(i/2) >> (32*(i%2))) & 0xffffffffL)
      }
      def read(): Seq[BigInt] = (0 until 25).map { i =>
        command(1, 2*i, hold = random.nextInt(3)) | (command(1, 2*i+1) << 32)
      }
      command(3, hold = 7); assertZero()
      val shadow = Array.fill[BigInt](50)(0)
      for (i <- 0 until 64) {
        val value = (BigInt("89abcdef", 16) ^ (BigInt("9e3779b9", 16)*(i+1))) & 0xffffffffL
        command(0, i, value, hold = i % 3)
        if (i < 50) shadow(i) = value
        // Check the entire bank after EVERY write, before later writes could
        // hide corruption of a different word or the other half of the lane.
        assert(dut.state.map(_.toBigInt).toSeq == (0 until 25).map(l => shadow(2*l) | (shadow(2*l+1) << 32)), s"write isolation index=$i")
        assert(command(1, i, hold = i % 4) == (if (i < 50) value else BigInt(0)))
      }

      for ((v, sample) <- vectors.zipWithIndex) {
        if (sample != 3) load(v.head) // sample3 is a consecutive KPERM, no reload
        assert(dut.state.map(_.toBigInt).toSeq == v.head)
        accept(2)
        if (sample < 3) {
          tick(blocks)
          assert(dut.state.map(_.toBigInt).toSeq == v(2), s"initial theta sample=$sample")
          for (r <- 0 until 24) {
            tick(1+blocks)
            assert(dut.state.map(_.toBigInt).toSeq == v(3+r), s"boundary sample=$sample round=$r")
          }
          assert(dut.io.rsp.valid.toBoolean)
          // Already counted these work edges; only consume the held response.
          dut.io.rsp.ready #= true; tick(); dut.io.rsp.ready #= false
        } else finish(2, random.nextInt(9))
        assert(read() == v(1), s"permutation sample=$sample Nb=$blocks")
      }

      // Reset aborts every slice of theta/rho/pi/fold in first and last rounds,
      // scrub at every position, and a pending response. No old payload survives.
      val l = KeccakSliced.permutationCycles(blocks)
      val offsets = ((0 to blocks+2) ++ (l-blocks-2 to l)).distinct
      for (offset <- offsets) {
        load(vectors(1).head); accept(2); tick(offset); reset()
        assert(read().forall(_ == 0))
      }
      for (offset <- 0 until blocks) {
        load(vectors(1).head); accept(3); tick(offset); reset()
      }
      for (offset <- 0 until blocks; index <- Seq(0, 1, 48, 49, 63)) {
        load(vectors(1).head); accept(0, index, 0x89abcdefL); tick(offset); reset()
        assert(read().forall(_ == 0))
      }
      load(vectors(1).head); accept(1, 48)
      assert(dut.io.rsp.valid.toBoolean && dut.io.rsp.payload.toBigInt == 24)
      reset(); assert(dut.io.rsp.payload.toBigInt == 0)
      load(vectors(1).head); command(3); assertZero()
      assert(read().forall(_ == 0))
      println(s"SLICED_PASS blocks=$blocks vectors=${vectors.length} random=1000 latency=$l directedResetCases=${offsets.length+6*blocks+1}")
    }
  }
}
