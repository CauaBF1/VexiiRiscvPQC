package vexiiriscv.execute

import spinal.core._
import spinal.core.sim._
import spinal.lib.misc.plugin.FiberPlugin
import vexiiriscv.ParamSimple
import vexiiriscv.tester.{TestBench, TestBenchDut, TestOptions}

/** Directed probe of the actual CPU/plugin, not a duplicate handshake model. */
class KeccakSlicedObserve(hold: Boolean) extends FiberPlugin {
  val logic = during setup new Area {
    val pipeline = host[ExecutePipelinePlugin]
    val lock = retains(pipeline.pipelineLock)
    awaitBuild()
    val core = host[KeccakSlicedPlugin].logic.process.core
    val op = Reg(UInt(2 bits)) init 0
    when(core.io.cmd.fire) {
      op := core.io.cmd.op
      switch(core.io.cmd.op) {
        is(0) { report("SLICED_CMD_WRITE") }
        is(1) { report("SLICED_CMD_READ") }
        is(2) { report("SLICED_CMD_PERM") }
        is(3) { report("SLICED_CMD_CLEAR") }
      }
    }
    when(core.io.rsp.fire) {
      switch(op) {
        is(0) { report("SLICED_RSP_WRITE") }
        is(1) { report("SLICED_RSP_READ") }
        is(2) { report("SLICED_RSP_PERM") }
        is(3) { report("SLICED_RSP_CLEAR") }
      }
    }
    if (hold) {
      val afterAccept = Reg(UInt(3 bits)) init 0
      when(core.io.cmd.fire) { afterAccept := 4 }
        .elsewhen(afterAccept =/= 0) { afterAccept := afterAccept - 1 }
      val responseWait = Reg(UInt(3 bits)) init 0
      when(!core.io.rsp.valid) { responseWait := 0 }
        .elsewhen(responseWait < 5) { responseWait := responseWait + 1 }
      pipeline.freezeWhen(core.io.cmd.fire || afterAccept =/= 0 || (core.io.rsp.valid && responseWait < 5))
      when(core.io.rsp.valid && responseWait === 0) { report("SLICED_RESPONSE_HELD") }
    }
    lock.release()
  }
}

object KeccakSlicedPipelineProbe extends App {
  val param = new ParamSimple()
  val test = new TestOptions()
  var hold = false
  val parser = new scopt.OptionParser[Unit]("KeccakSlicedPipelineProbe") {
    opt[Unit]("hold-responses").action { (_, _) => hold = true }
    test.addOptions(this); param.addOptions(this)
  }
  assert(parser.parse(args, ()).nonEmpty)
  param.withKeccak = true
  require(param.keccakSlicedBlocks != 0, "select --keccak-architecture sliced8 or sliced16")
  val config = SpinalConfig(); config.includeSimulation
  val compiled = SimConfig.withConfig(config).compile {
    // Reuse the normal memory/PMA setup, including the native LSU-L1 TileLink
    // bridge. Instantiating just ParamSimple.pluginsArea omits that bridge.
    val plugins = TestBench.paramToPlugins(param)
    plugins += new KeccakSlicedObserve(hold)
    new TestBenchDut(Seq(plugins))
  }
  test.test(compiled)
}
