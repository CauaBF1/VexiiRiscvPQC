package vexiiriscv

import org.scalatest.funsuite.AnyFunSuite

class ParamKeccakSpec extends AnyFunSuite {
  private def parse(options: Seq[String]): ParamSimple = {
    val param = new ParamSimple()
    val parser = new scopt.OptionParser[Unit]("VexiiRiscv") {
      param.addOptions(this)
    }
    assert(parser.parse(options, ()).nonEmpty)
    param
  }

  test("Keccak plugin is opt-in and represented in the configuration identity") {
    val baseline = parse(Seq.empty)
    val keccak = parse(Seq("--with-keccak"))
    val all = parse(Seq("--with-montmul", "--with-montred", "--with-keccak"))

    assert(!baseline.withKeccak)
    assert(keccak.withKeccak && !keccak.withMontMul && !keccak.withMontRed)
    assert(all.withKeccak && all.withMontMul && all.withMontRed)

    assert(!baseline.getName().contains("keccak"))
    assert(keccak.getName().contains("keccak"))
    assert(all.getName().contains("montmul"))
    assert(all.getName().contains("montred"))
    assert(all.getName().contains("keccak"))

    assert(Set(baseline.hashCode(), keccak.hashCode(), all.hashCode()).size == 3)
  }
}
