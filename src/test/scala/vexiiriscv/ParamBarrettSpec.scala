package vexiiriscv

import org.scalatest.funsuite.AnyFunSuite

class ParamBarrettSpec extends AnyFunSuite {
  private def parse(args: Seq[String]): Option[ParamSimple] = {
    val p = new ParamSimple()
    val parser = new scopt.OptionParser[Unit]("VexiiRiscv") { p.addOptions(this) }
    parser.parse(args, ()).map(_ => p)
  }

  test("Barrett is opt-in and coexists with Montgomery and Keccak") {
    val baseline = parse(Seq.empty).get
    val barrett = parse(Seq("--with-barrett")).get
    val mont = parse(Seq("--with-montmul", "--with-montred")).get
    val combined = parse(Seq("--with-montmul", "--with-montred", "--with-barrett")).get
    val all = parse(Seq("--with-montmul", "--with-montred", "--with-barrett", "--with-keccak")).get
    assert(!baseline.withBarrett && !mont.withBarrett)
    assert(barrett.withBarrett && !barrett.withMontMul && !barrett.withKeccak)
    assert(combined.withBarrett && combined.withMontMul && combined.withMontRed && !combined.withKeccak)
    assert(all.withBarrett && all.withKeccak)
    assert(barrett.getName().contains("barrett"))
    assert(Set(baseline.hashCode(), barrett.hashCode(), mont.hashCode(), combined.hashCode(), all.hashCode()).size == 5)
  }

  test("CFU conflict is rejected in both option orders and direct configuration") {
    assert(parse(Seq("--with-barrett", "--with-cfu")).isEmpty)
    assert(parse(Seq("--with-cfu", "--with-barrett")).isEmpty)
    val direct = new ParamSimple()
    direct.withBarrett = true
    direct.withCfu = true
    intercept[IllegalArgumentException] { direct.checkCustomInstructionCompatibility() }
  }
}
