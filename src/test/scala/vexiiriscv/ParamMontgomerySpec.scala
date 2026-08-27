package vexiiriscv

import org.scalatest.funsuite.AnyFunSuite

class ParamMontgomerySpec extends AnyFunSuite {
  private def parse(options: Seq[String]): ParamSimple = {
    val param = new ParamSimple()
    val parser = new scopt.OptionParser[Unit]("VexiiRiscv") {
      param.addOptions(this)
    }
    assert(parser.parse(options, ()).nonEmpty)
    param
  }

  test("Montgomery plugins are opt-in and represented in the configuration identity") {
    val baseline = parse(Seq.empty)
    val montmul = parse(Seq("--with-montmul"))
    val montred = parse(Seq("--with-montred"))
    val both = parse(Seq("--with-montmul", "--with-montred"))

    assert(!baseline.withMontMul && !baseline.withMontRed)
    assert(montmul.withMontMul && !montmul.withMontRed)
    assert(!montred.withMontMul && montred.withMontRed)
    assert(both.withMontMul && both.withMontRed)

    assert(!baseline.getName().contains("mont"))
    assert(montmul.getName().contains("montmul"))
    assert(montred.getName().contains("montred"))
    assert(both.getName().contains("montmul") && both.getName().contains("montred"))

    assert(Set(baseline.hashCode(), montmul.hashCode(), montred.hashCode(), both.hashCode()).size == 4)
  }
}
