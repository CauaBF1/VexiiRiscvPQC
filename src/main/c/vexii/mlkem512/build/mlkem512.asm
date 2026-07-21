
build/mlkem512.elf:     file format elf64-littleriscv


Disassembly of section ._vector:

0000000080000000 <crtStart>:
.global pass
.global fail

    .section .start_jump,"ax",@progbits
crtStart:
  j crtInit
    80000000:	3200006f          	j	80000320 <crtInit>

0000000080000004 <print>:
/* VexiiRiscv PeripheralEmulator, base 0x10000000 (see
 * src/main/scala/vexiiriscv/test/PeripheralEmulator.scala). */
#define SIM_BASE 0x10000000UL
#define SIM_PUTC (*(volatile uint8_t *)(SIM_BASE + 0x00))

static inline void sim_putc(char c) { SIM_PUTC = (uint8_t)c; }
    80000004:	10000737          	lui	a4,0x10000
static uint8_t ct[MLKEM512_CIPHERTEXTBYTES];
static uint8_t ss1[MLKEM512_BYTES];
static uint8_t ss2[MLKEM512_BYTES];

static void print(const char *str) {
  while (*str) sim_putc(*str++);
    80000008:	00054783          	lbu	a5,0(a0)
    8000000c:	e391                	bnez	a5,80000010 <print+0xc>
}
    8000000e:	8082                	ret
  while (*str) sim_putc(*str++);
    80000010:	0505                	addi	a0,a0,1
    80000012:	00f70023          	sb	a5,0(a4) # 10000000 <_stack_size+0xfff0000>
    80000016:	bfcd                	j	80000008 <print+0x4>

0000000080000018 <bytes_equal>:
    sim_putc(digit < 10 ? ('0' + digit) : ('A' + digit - 10));
  }
}

static int bytes_equal(const uint8_t *lhs, const uint8_t *rhs, size_t n) {
  for (size_t i = 0; i < n; i++) {
    80000018:	4781                	li	a5,0
    if (lhs[i] != rhs[i]) return 0;
    8000001a:	00f506b3          	add	a3,a0,a5
    8000001e:	00f58733          	add	a4,a1,a5
    80000022:	0006c683          	lbu	a3,0(a3)
    80000026:	00074703          	lbu	a4,0(a4)
    8000002a:	00e69763          	bne	a3,a4,80000038 <bytes_equal+0x20>
  for (size_t i = 0; i < n; i++) {
    8000002e:	0785                	addi	a5,a5,1
    80000030:	fef615e3          	bne	a2,a5,8000001a <bytes_equal+0x2>
  }
  return 1;
    80000034:	4505                	li	a0,1
    80000036:	8082                	ret
    if (lhs[i] != rhs[i]) return 0;
    80000038:	4501                	li	a0,0
}
    8000003a:	8082                	ret

000000008000003c <print_result>:

static void print_result(const char *label, int value) {
    8000003c:	1101                	addi	sp,sp,-32
    8000003e:	e42e                	sd	a1,8(sp)
    80000040:	ec06                	sd	ra,24(sp)
  print(label);
    80000042:	fc3ff0ef          	jal	80000004 <print>
  print("=0x");
    80000046:	00002517          	auipc	a0,0x2
    8000004a:	53a50513          	addi	a0,a0,1338 # 80002580 <mlkem_keccakf1600_permute+0xe>
    8000004e:	fb7ff0ef          	jal	80000004 <print>
  for (int i = 7; i >= 0; i--) {
    80000052:	65a2                	ld	a1,8(sp)
  print_hex32((uint32_t)value);
    80000054:	4771                	li	a4,28
    sim_putc(digit < 10 ? ('0' + digit) : ('A' + digit - 10));
    80000056:	4825                	li	a6,9
    80000058:	100006b7          	lui	a3,0x10000
  for (int i = 7; i >= 0; i--) {
    8000005c:	5571                	li	a0,-4
    uint32_t digit = (value >> (i * 4)) & 0xF;
    8000005e:	00e5d7bb          	srlw	a5,a1,a4
    80000062:	8bbd                	andi	a5,a5,15
    sim_putc(digit < 10 ? ('0' + digit) : ('A' + digit - 10));
    80000064:	03778613          	addi	a2,a5,55
    80000068:	00f86463          	bltu	a6,a5,80000070 <print_result+0x34>
    8000006c:	03078613          	addi	a2,a5,48
    80000070:	00c68023          	sb	a2,0(a3) # 10000000 <_stack_size+0xfff0000>
  for (int i = 7; i >= 0; i--) {
    80000074:	3771                	addiw	a4,a4,-4
    80000076:	fea714e3          	bne	a4,a0,8000005e <print_result+0x22>
    8000007a:	47a9                	li	a5,10
    8000007c:	00f68023          	sb	a5,0(a3)
  sim_putc('\n');
}
    80000080:	60e2                	ld	ra,24(sp)
    80000082:	6105                	addi	sp,sp,32
    80000084:	8082                	ret

0000000080000086 <main>:
  print_result("kat_pass", pass);

  return pass;
}

int main(void) {
    80000086:	715d                	addi	sp,sp,-80
  print(str);
    80000088:	00002517          	auipc	a0,0x2
    8000008c:	50050513          	addi	a0,a0,1280 # 80002588 <mlkem_keccakf1600_permute+0x16>
int main(void) {
    80000090:	e486                	sd	ra,72(sp)
    80000092:	f84a                	sd	s2,48(sp)
    80000094:	f44e                	sd	s3,40(sp)
    80000096:	f052                	sd	s4,32(sp)
    80000098:	ec56                	sd	s5,24(sp)
    8000009a:	e85a                	sd	s6,16(sp)
    8000009c:	e45e                	sd	s7,8(sp)
    8000009e:	e0a2                	sd	s0,64(sp)
    800000a0:	fc26                	sd	s1,56(sp)
  print(str);
    800000a2:	f63ff0ef          	jal	80000004 <print>
    800000a6:	100007b7          	lui	a5,0x10000
    800000aa:	4729                	li	a4,10
    800000ac:	00e78023          	sb	a4,0(a5) # 10000000 <_stack_size+0xfff0000>
  int keypair_ret = mlkem_keypair_derand(pk, sk, kat_keypair_coins);
    800000b0:	00002617          	auipc	a2,0x2
    800000b4:	57060613          	addi	a2,a2,1392 # 80002620 <kat_keypair_coins>
    800000b8:	81818593          	addi	a1,gp,-2024 # 800034f8 <sk>
    800000bc:	e7818513          	addi	a0,gp,-392 # 80003b58 <pk>
    800000c0:	418020ef          	jal	800024d8 <mlkem_keypair_derand>
  int enc_ret = mlkem_enc_derand(ct, ss1, pk, kat_enc_coins);
    800000c4:	00002697          	auipc	a3,0x2
    800000c8:	59c68693          	addi	a3,a3,1436 # 80002660 <kat_enc_coins>
    800000cc:	e7818613          	addi	a2,gp,-392 # 80003b58 <pk>
    800000d0:	19818593          	addi	a1,gp,408 # 80003e78 <ss1>
  int keypair_ret = mlkem_keypair_derand(pk, sk, kat_keypair_coins);
    800000d4:	892a                	mv	s2,a0
  int enc_ret = mlkem_enc_derand(ct, ss1, pk, kat_enc_coins);
    800000d6:	1b818513          	addi	a0,gp,440 # 80003e98 <ct>
    800000da:	01c020ef          	jal	800020f6 <mlkem_enc_derand>
  int dec_ret = mlkem_dec(ss2, ct, sk);
    800000de:	81818613          	addi	a2,gp,-2024 # 800034f8 <sk>
    800000e2:	1b818593          	addi	a1,gp,440 # 80003e98 <ct>
  int enc_ret = mlkem_enc_derand(ct, ss1, pk, kat_enc_coins);
    800000e6:	89aa                	mv	s3,a0
  int dec_ret = mlkem_dec(ss2, ct, sk);
    800000e8:	4b818513          	addi	a0,gp,1208 # 80004198 <ss2>
    800000ec:	497010ef          	jal	80001d82 <mlkem_dec>
  int pk_match = bytes_equal(pk, kat_pk, sizeof(pk));
    800000f0:	32000613          	li	a2,800
    800000f4:	00002597          	auipc	a1,0x2
    800000f8:	58c58593          	addi	a1,a1,1420 # 80002680 <kat_pk>
  int dec_ret = mlkem_dec(ss2, ct, sk);
    800000fc:	8a2a                	mv	s4,a0
  int pk_match = bytes_equal(pk, kat_pk, sizeof(pk));
    800000fe:	e7818513          	addi	a0,gp,-392 # 80003b58 <pk>
    80000102:	f17ff0ef          	jal	80000018 <bytes_equal>
  int sk_match = bytes_equal(sk, kat_sk, sizeof(sk));
    80000106:	66000613          	li	a2,1632
    8000010a:	00003597          	auipc	a1,0x3
    8000010e:	89658593          	addi	a1,a1,-1898 # 800029a0 <kat_sk>
  int pk_match = bytes_equal(pk, kat_pk, sizeof(pk));
    80000112:	8aaa                	mv	s5,a0
  int sk_match = bytes_equal(sk, kat_sk, sizeof(sk));
    80000114:	81818513          	addi	a0,gp,-2024 # 800034f8 <sk>
    80000118:	f01ff0ef          	jal	80000018 <bytes_equal>
  int ct_match = bytes_equal(ct, kat_ct, sizeof(ct));
    8000011c:	30000613          	li	a2,768
    80000120:	00003597          	auipc	a1,0x3
    80000124:	ee058593          	addi	a1,a1,-288 # 80003000 <kat_ct>
  int sk_match = bytes_equal(sk, kat_sk, sizeof(sk));
    80000128:	8b2a                	mv	s6,a0
  int ct_match = bytes_equal(ct, kat_ct, sizeof(ct));
    8000012a:	1b818513          	addi	a0,gp,440 # 80003e98 <ct>
    8000012e:	eebff0ef          	jal	80000018 <bytes_equal>
    80000132:	8baa                	mv	s7,a0
  int ss_match = bytes_equal(ss1, kat_ss, sizeof(ss1)) && bytes_equal(ss2, kat_ss, sizeof(ss2));
    80000134:	02000613          	li	a2,32
    80000138:	00003597          	auipc	a1,0x3
    8000013c:	1c858593          	addi	a1,a1,456 # 80003300 <kat_ss>
    80000140:	19818513          	addi	a0,gp,408 # 80003e78 <ss1>
    80000144:	ed5ff0ef          	jal	80000018 <bytes_equal>
    80000148:	c919                	beqz	a0,8000015e <main+0xd8>
    8000014a:	02000613          	li	a2,32
    8000014e:	00003597          	auipc	a1,0x3
    80000152:	1b258593          	addi	a1,a1,434 # 80003300 <kat_ss>
    80000156:	4b818513          	addi	a0,gp,1208 # 80004198 <ss2>
    8000015a:	ebfff0ef          	jal	80000018 <bytes_equal>
  pass &= dec_ret == 0;
    8000015e:	01396433          	or	s0,s2,s3
    80000162:	008a6433          	or	s0,s4,s0
  pass &= ct_match;
    80000166:	016af7b3          	and	a5,s5,s6
  pass &= dec_ret == 0;
    8000016a:	2401                	sext.w	s0,s0
  pass &= ct_match;
    8000016c:	00fbf7b3          	and	a5,s7,a5
  pass &= dec_ret == 0;
    80000170:	00143413          	seqz	s0,s0
  pass &= ct_match;
    80000174:	8c7d                	and	s0,s0,a5
  pass &= ss_match;
    80000176:	8c69                	and	s0,s0,a0
    80000178:	84aa                	mv	s1,a0
  print_result("keypair_ret", keypair_ret);
    8000017a:	85ca                	mv	a1,s2
    8000017c:	00002517          	auipc	a0,0x2
    80000180:	42c50513          	addi	a0,a0,1068 # 800025a8 <mlkem_keccakf1600_permute+0x36>
    80000184:	eb9ff0ef          	jal	8000003c <print_result>
  print_result("enc_ret", enc_ret);
    80000188:	85ce                	mv	a1,s3
    8000018a:	00002517          	auipc	a0,0x2
    8000018e:	42e50513          	addi	a0,a0,1070 # 800025b8 <mlkem_keccakf1600_permute+0x46>
    80000192:	eabff0ef          	jal	8000003c <print_result>
  print_result("dec_ret", dec_ret);
    80000196:	85d2                	mv	a1,s4
    80000198:	00002517          	auipc	a0,0x2
    8000019c:	42850513          	addi	a0,a0,1064 # 800025c0 <mlkem_keccakf1600_permute+0x4e>
    800001a0:	e9dff0ef          	jal	8000003c <print_result>
  print_result("pk_match", pk_match);
    800001a4:	85d6                	mv	a1,s5
    800001a6:	00002517          	auipc	a0,0x2
    800001aa:	42250513          	addi	a0,a0,1058 # 800025c8 <mlkem_keccakf1600_permute+0x56>
    800001ae:	e8fff0ef          	jal	8000003c <print_result>
  print_result("sk_match", sk_match);
    800001b2:	85da                	mv	a1,s6
    800001b4:	00002517          	auipc	a0,0x2
    800001b8:	42450513          	addi	a0,a0,1060 # 800025d8 <mlkem_keccakf1600_permute+0x66>
    800001bc:	e81ff0ef          	jal	8000003c <print_result>
  print_result("ct_match", ct_match);
    800001c0:	85de                	mv	a1,s7
    800001c2:	00002517          	auipc	a0,0x2
    800001c6:	42650513          	addi	a0,a0,1062 # 800025e8 <mlkem_keccakf1600_permute+0x76>
    800001ca:	e73ff0ef          	jal	8000003c <print_result>
  print_result("ss_match", ss_match);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	00002517          	auipc	a0,0x2
    800001d4:	42850513          	addi	a0,a0,1064 # 800025f8 <mlkem_keccakf1600_permute+0x86>
    800001d8:	e65ff0ef          	jal	8000003c <print_result>
  print_result("kat_pass", pass);
    800001dc:	85a2                	mv	a1,s0
    800001de:	00002517          	auipc	a0,0x2
    800001e2:	42a50513          	addi	a0,a0,1066 # 80002608 <mlkem_keccakf1600_permute+0x96>
    800001e6:	e57ff0ef          	jal	8000003c <print_result>
  print(str);
    800001ea:	00002517          	auipc	a0,0x2
    800001ee:	42e50513          	addi	a0,a0,1070 # 80002618 <mlkem_keccakf1600_permute+0xa6>
    800001f2:	e13ff0ef          	jal	80000004 <print>
    800001f6:	100007b7          	lui	a5,0x10000
    800001fa:	4729                	li	a4,10
    800001fc:	00e78023          	sb	a4,0(a5) # 10000000 <_stack_size+0xfff0000>
  println("VexiiRiscv ML-KEM-512 KAT start");
  int pass = run_kat();
  println("done");
  return pass ? 0 : 1; /* crt.S routes 0 -> pass symbol, non-zero -> fail */
}
    80000200:	60a6                	ld	ra,72(sp)
    80000202:	00144513          	xori	a0,s0,1
    80000206:	6406                	ld	s0,64(sp)
    80000208:	74e2                	ld	s1,56(sp)
    8000020a:	7942                	ld	s2,48(sp)
    8000020c:	79a2                	ld	s3,40(sp)
    8000020e:	7a02                	ld	s4,32(sp)
    80000210:	6ae2                	ld	s5,24(sp)
    80000212:	6b42                	ld	s6,16(sp)
    80000214:	6ba2                	ld	s7,8(sp)
    80000216:	6161                	addi	sp,sp,80
    80000218:	8082                	ret

000000008000021a <randombytes>:
#include <stdint.h>

static uint32_t rng_state = 0x12345678u;

int randombytes(uint8_t *buf, size_t n) {
  for (size_t i = 0; i < n; i++) {
    8000021a:	00003797          	auipc	a5,0x3
    8000021e:	2c67a783          	lw	a5,710(a5) # 800034e0 <rng_state>
    80000222:	4681                	li	a3,0
    80000224:	4701                	li	a4,0
    80000226:	00b71963          	bne	a4,a1,80000238 <randombytes+0x1e>
    8000022a:	c689                	beqz	a3,80000234 <randombytes+0x1a>
    8000022c:	00003717          	auipc	a4,0x3
    80000230:	2af72a23          	sw	a5,692(a4) # 800034e0 <rng_state>
    rng_state ^= rng_state << 5;
    buf[i] = (uint8_t)(rng_state & 0xFF);
  }

  return 0;
}
    80000234:	4501                	li	a0,0
    80000236:	8082                	ret
    rng_state ^= rng_state << 13;
    80000238:	00d7969b          	slliw	a3,a5,0xd
    8000023c:	8fb5                	xor	a5,a5,a3
    rng_state ^= rng_state >> 17;
    8000023e:	0117d69b          	srliw	a3,a5,0x11
    80000242:	8ebd                	xor	a3,a3,a5
    rng_state ^= rng_state << 5;
    80000244:	0056979b          	slliw	a5,a3,0x5
    80000248:	8fb5                	xor	a5,a5,a3
    buf[i] = (uint8_t)(rng_state & 0xFF);
    8000024a:	00e506b3          	add	a3,a0,a4
    8000024e:	00f68023          	sb	a5,0(a3)
  for (size_t i = 0; i < n; i++) {
    80000252:	0705                	addi	a4,a4,1
    80000254:	4685                	li	a3,1
    80000256:	bfc1                	j	80000226 <randombytes+0xc>

0000000080000258 <memcpy>:

void *memcpy(void *dest, const void *src, size_t n) {
  uint8_t *d = (uint8_t *)dest;
  const uint8_t *s = (const uint8_t *)src;

  for (size_t i = 0; i < n; i++) {
    80000258:	4781                	li	a5,0
    8000025a:	00c79363          	bne	a5,a2,80000260 <memcpy+0x8>
    d[i] = s[i];
  }

  return dest;
}
    8000025e:	8082                	ret
    d[i] = s[i];
    80000260:	00f58733          	add	a4,a1,a5
    80000264:	00074683          	lbu	a3,0(a4)
    80000268:	00f50733          	add	a4,a0,a5
  for (size_t i = 0; i < n; i++) {
    8000026c:	0785                	addi	a5,a5,1
    d[i] = s[i];
    8000026e:	00d70023          	sb	a3,0(a4)
  for (size_t i = 0; i < n; i++) {
    80000272:	b7e5                	j	8000025a <memcpy+0x2>

0000000080000274 <memset>:

void *memset(void *dest, int value, size_t n) {
  uint8_t *d = (uint8_t *)dest;

  for (size_t i = 0; i < n; i++) {
    80000274:	4781                	li	a5,0
    80000276:	00c79363          	bne	a5,a2,8000027c <memset+0x8>
    d[i] = (uint8_t)value;
  }

  return dest;
}
    8000027a:	8082                	ret
    d[i] = (uint8_t)value;
    8000027c:	00f50733          	add	a4,a0,a5
    80000280:	00b70023          	sb	a1,0(a4)
  for (size_t i = 0; i < n; i++) {
    80000284:	0785                	addi	a5,a5,1
    80000286:	bfc5                	j	80000276 <memset+0x2>

0000000080000288 <memcmp>:

int memcmp(const void *lhs, const void *rhs, size_t n) {
  const uint8_t *a = (const uint8_t *)lhs;
  const uint8_t *b = (const uint8_t *)rhs;

  for (size_t i = 0; i < n; i++) {
    80000288:	4701                	li	a4,0
    8000028a:	00c71463          	bne	a4,a2,80000292 <memcmp+0xa>
    if (a[i] != b[i]) {
      return (int)a[i] - (int)b[i];
    }
  }

  return 0;
    8000028e:	4501                	li	a0,0
}
    80000290:	8082                	ret
    if (a[i] != b[i]) {
    80000292:	00e507b3          	add	a5,a0,a4
    80000296:	00e586b3          	add	a3,a1,a4
    8000029a:	0007c783          	lbu	a5,0(a5)
    8000029e:	0006c683          	lbu	a3,0(a3)
    800002a2:	00d78563          	beq	a5,a3,800002ac <memcmp+0x24>
      return (int)a[i] - (int)b[i];
    800002a6:	40d7853b          	subw	a0,a5,a3
    800002aa:	8082                	ret
  for (size_t i = 0; i < n; i++) {
    800002ac:	0705                	addi	a4,a4,1
    800002ae:	bff1                	j	8000028a <memcmp+0x2>

00000000800002b0 <malloc>:

void *malloc(size_t size) {
  if (size == 0) {
    800002b0:	e119                	bnez	a0,800002b6 <malloc+0x6>
    return 0;
    800002b2:	4501                	li	a0,0
    800002b4:	8082                	ret
  }

  if (heap_current == 0) {
    800002b6:	00003797          	auipc	a5,0x3
    800002ba:	2327b783          	ld	a5,562(a5) # 800034e8 <heap_current>
    800002be:	e799                	bnez	a5,800002cc <malloc+0x1c>
    heap_current = (uintptr_t)&_heap_start;
    800002c0:	4d818793          	addi	a5,gp,1240 # 800041b8 <_bss_end>
    800002c4:	00003717          	auipc	a4,0x3
    800002c8:	22f73223          	sd	a5,548(a4) # 800034e8 <heap_current>
  return (value + alignment - 1u) & ~(alignment - 1u);
    800002cc:	079d                	addi	a5,a5,7
    800002ce:	ff87f713          	andi	a4,a5,-8
  }

  uintptr_t header = align_up(heap_current, 8u);
  uintptr_t start = header + sizeof(uintptr_t);
    800002d2:	00870693          	addi	a3,a4,8
  return (value + alignment - 1u) & ~(alignment - 1u);
    800002d6:	00750793          	addi	a5,a0,7
    800002da:	97b6                	add	a5,a5,a3
    800002dc:	9be1                	andi	a5,a5,-8
  uintptr_t end = align_up(start + size, 8u);

  if (end > (uintptr_t)&_heap_end) {
    800002de:	00008617          	auipc	a2,0x8
    800002e2:	eda60613          	addi	a2,a2,-294 # 800081b8 <_heap_end>
    800002e6:	fcf666e3          	bltu	a2,a5,800002b2 <malloc+0x2>
    return 0;
  }

  *((uintptr_t *)header) = end - header;
    800002ea:	40e78633          	sub	a2,a5,a4
    800002ee:	e310                	sd	a2,0(a4)
  heap_current = end;
  return (void *)start;
    800002f0:	8536                	mv	a0,a3
  heap_current = end;
    800002f2:	00003717          	auipc	a4,0x3
    800002f6:	1ef73b23          	sd	a5,502(a4) # 800034e8 <heap_current>
}
    800002fa:	8082                	ret

00000000800002fc <free>:

void free(void *ptr) {
  if (ptr == 0) {
    800002fc:	c105                	beqz	a0,8000031c <free+0x20>
  }

  uintptr_t header = (uintptr_t)ptr - sizeof(uintptr_t);
  uintptr_t size = *((uintptr_t *)header);

  if (header + size == heap_current) {
    800002fe:	ff853783          	ld	a5,-8(a0)
    80000302:	00003697          	auipc	a3,0x3
    80000306:	1e66b683          	ld	a3,486(a3) # 800034e8 <heap_current>
  uintptr_t header = (uintptr_t)ptr - sizeof(uintptr_t);
    8000030a:	ff850713          	addi	a4,a0,-8
  if (header + size == heap_current) {
    8000030e:	97ba                	add	a5,a5,a4
    80000310:	00d79663          	bne	a5,a3,8000031c <free+0x20>
    heap_current = header;
    80000314:	00003797          	auipc	a5,0x3
    80000318:	1ce7ba23          	sd	a4,468(a5) # 800034e8 <heap_current>
  }
}
    8000031c:	8082                	ret

000000008000031e <exit>:

void exit(int status) {
  (void)status;
  while (1) {
    8000031e:	a001                	j	8000031e <exit>

0000000080000320 <crtInit>:
.section .text

crtInit:
  .option push
  .option norelax
  la gp, __global_pointer$
    80000320:	00004197          	auipc	gp,0x4
    80000324:	9c018193          	addi	gp,gp,-1600 # 80003ce0 <__global_pointer$>
  .option pop
  la sp, _stack_start
    80000328:	00018117          	auipc	sp,0x18
    8000032c:	e9810113          	addi	sp,sp,-360 # 800181c0 <_stack_start>

0000000080000330 <bss_init>:

bss_init:
  la a0, _bss_start
    80000330:	80818513          	addi	a0,gp,-2040 # 800034e8 <heap_current>
  la a1, _bss_end
    80000334:	00004597          	auipc	a1,0x4
    80000338:	e8458593          	addi	a1,a1,-380 # 800041b8 <_bss_end>

000000008000033c <bss_loop>:
bss_loop:
  beq a0, a1, bss_done
    8000033c:	00b50663          	beq	a0,a1,80000348 <bss_done>
  sd zero, 0(a0)          /* _bss_start/_bss_end are 8-aligned by linker.ld */
    80000340:	00053023          	sd	zero,0(a0)
  addi a0, a0, 8
    80000344:	0521                	addi	a0,a0,8
  j bss_loop
    80000346:	bfdd                	j	8000033c <bss_loop>

0000000080000348 <bss_done>:
bss_done:

  call main
    80000348:	d3fff0ef          	jal	80000086 <main>
  bnez a0, fail           /* main returns non-zero -> failure */
    8000034c:	e501                	bnez	a0,80000354 <fail>
    8000034e:	0001                	nop

0000000080000350 <pass>:

.align 2
pass:
  j pass
    80000350:	a001                	j	80000350 <pass>
    80000352:	0001                	nop

0000000080000354 <fail>:
.align 2
fail:
  j fail
    80000354:	a001                	j	80000354 <fail>
    80000356:	0001                	nop

0000000080000358 <mlk_zeroize>:
#define MLK_CONFIG_CUSTOM_ZEROIZE

static inline void mlk_zeroize(void *ptr, size_t len) {
  volatile uint8_t *p = (volatile uint8_t *)ptr;

  while (len-- != 0) {
    80000358:	95aa                	add	a1,a1,a0
    *p++ = 0;
    8000035a:	87aa                	mv	a5,a0
    8000035c:	00078023          	sb	zero,0(a5)
    80000360:	0505                	addi	a0,a0,1
  while (len-- != 0) {
    80000362:	feb51ce3          	bne	a0,a1,8000035a <mlk_zeroize+0x2>
  }
}
    80000366:	8082                	ret

0000000080000368 <mlkem_poly_add>:
/* Reference: `poly_add()` in the reference implementation @[REF].
 *            - We use destructive version (output=first input) to avoid
 *              reasoning about aliasing in the CBMC specification */
MLK_INTERNAL_API
void mlk_poly_add(mlk_poly *r, const mlk_poly *b)
{
    80000368:	4781                	li	a5,0
  unsigned i;
  for (i = 0; i < MLKEM_N; i++)
    8000036a:	20000613          	li	a2,512
    invariant(forall(k0, i, MLKEM_N, r->coeffs[k0] == loop_entry(*r).coeffs[k0]))
    invariant(forall(k1, 0, i, r->coeffs[k1] == loop_entry(*r).coeffs[k1] + b->coeffs[k1]))
    decreases(MLKEM_N - i))
  {
    /* The preconditions imply that the addition stays within int16_t. */
    r->coeffs[i] = (int16_t)(r->coeffs[i] + b->coeffs[i]);
    8000036e:	00f506b3          	add	a3,a0,a5
    80000372:	00f58733          	add	a4,a1,a5
    80000376:	00075703          	lhu	a4,0(a4)
    8000037a:	0006d803          	lhu	a6,0(a3)
  for (i = 0; i < MLKEM_N; i++)
    8000037e:	0789                	addi	a5,a5,2
    r->coeffs[i] = (int16_t)(r->coeffs[i] + b->coeffs[i]);
    80000380:	0107073b          	addw	a4,a4,a6
    80000384:	00e69023          	sh	a4,0(a3)
  for (i = 0; i < MLKEM_N; i++)
    80000388:	fec793e3          	bne	a5,a2,8000036e <mlkem_poly_add+0x6>
  }
}
    8000038c:	8082                	ret

000000008000038e <mlkem_polyvec_tobytes>:
void mlk_polyvec_tobytes(uint8_t r[MLKEM_POLYVECBYTES], const mlk_polyvec *a)
{
  unsigned i;
  mlk_assert_bound_2d(a->vec, MLKEM_K, MLKEM_N, 0, MLKEM_Q);

  for (i = 0; i < MLKEM_K; i++)
    8000038e:	40058813          	addi	a6,a1,1024
    80000392:	872e                	mv	a4,a1
    80000394:	18050613          	addi	a2,a0,384
           decreases(MLKEM_N / 2 - i))
  {
    /* The conversion to uint16_t is safe since we assume that
     * the coefficients of `a` are non-negative. */
    const uint16_t t0 = (uint16_t)a->coeffs[2 * i];
    const uint16_t t1 = (uint16_t)a->coeffs[2 * i + 1];
    80000398:	00271683          	lh	a3,2(a4)
    const uint16_t t0 = (uint16_t)a->coeffs[2 * i];
    8000039c:	00071783          	lh	a5,0(a4)
  for (i = 0; i < MLKEM_N / 2; i++)
    800003a0:	050d                	addi	a0,a0,3
     * nibble of the second byte. The least significant 4 bits
     * of t1 become the upper nibble of the second byte.
     *
     * The conversion to uint8_t does not alter the value.
     */
    r[3 * i + 1] = (uint8_t)((t0 >> 8) | ((t1 << 4) & 0xF0));
    800003a2:	0046989b          	slliw	a7,a3,0x4
    r[3 * i + 0] = (uint8_t)(t0 & 0xFF);
    800003a6:	fef50ea3          	sb	a5,-3(a0)
    r[3 * i + 1] = (uint8_t)((t0 >> 8) | ((t1 << 4) & 0xF0));
    800003aa:	0087d79b          	srliw	a5,a5,0x8
    800003ae:	0117e7b3          	or	a5,a5,a7

    /* Bits 4 - 11 of t1 become the third byte. The conversion to uint8_t
     * does not alter the value because t1 is 12-bit wide. */
    r[3 * i + 2] = (uint8_t)(t1 >> 4);
    800003b2:	0046d69b          	srliw	a3,a3,0x4
    r[3 * i + 1] = (uint8_t)((t0 >> 8) | ((t1 << 4) & 0xF0));
    800003b6:	fef50f23          	sb	a5,-2(a0)
    r[3 * i + 2] = (uint8_t)(t1 >> 4);
    800003ba:	fed50fa3          	sb	a3,-1(a0)
  for (i = 0; i < MLKEM_N / 2; i++)
    800003be:	0711                	addi	a4,a4,4
    800003c0:	fca61ce3          	bne	a2,a0,80000398 <mlkem_polyvec_tobytes+0xa>
    800003c4:	20058593          	addi	a1,a1,512
    800003c8:	00b81363          	bne	a6,a1,800003ce <mlkem_polyvec_tobytes+0x40>
    decreases(MLKEM_K - i)
  )
  {
    mlk_poly_tobytes(&r[i * MLKEM_POLYBYTES], &a->vec[i]);
  }
}
    800003cc:	8082                	ret
  for (i = 0; i < MLKEM_K; i++)
    800003ce:	8532                	mv	a0,a2
    800003d0:	b7c9                	j	80000392 <mlkem_polyvec_tobytes+0x4>

00000000800003d2 <mlkem_polyvec_frombytes>:
/* Reference: `polyvec_frombytes()` in the reference implementation @[REF]. */
MLK_INTERNAL_API
void mlk_polyvec_frombytes(mlk_polyvec *r, const uint8_t a[MLKEM_POLYVECBYTES])
{
  unsigned i;
  for (i = 0; i < MLKEM_K; i++)
    800003d2:	40050893          	addi	a7,a0,1024
    800003d6:	86aa                	mv	a3,a0
    800003d8:	18058813          	addi	a6,a1,384
    invariant(i <= MLKEM_N / 2)
    invariant(array_bound(r->coeffs, 0, 2 * i, 0, MLKEM_UINT12_LIMIT))
    decreases(MLKEM_N / 2 - i))
  {
    const uint8_t t0 = a[3 * i + 0];
    const uint8_t t1 = a[3 * i + 1];
    800003dc:	0015c603          	lbu	a2,1(a1)
    const uint8_t t2 = a[3 * i + 2];
    800003e0:	0025c783          	lbu	a5,2(a1)
    /* Safety:
     * - The explicit cast to uint16_t ensures that << 8 does
     *   not signed-overflow even on a 16-bit system.
     * - The cast to int16_t is safe due to the explicit 0xFFF truncation.
     */
    r->coeffs[2 * i + 0] = (int16_t)(t0 | (((uint16_t)t1 << 8) & 0xFFF));
    800003e4:	0005c303          	lbu	t1,0(a1)
    800003e8:	03c61713          	slli	a4,a2,0x3c
    800003ec:	9351                	srli	a4,a4,0x34
    r->coeffs[2 * i + 1] = (int16_t)((t1 >> 4) | (t2 << 4));
    800003ee:	0046561b          	srliw	a2,a2,0x4
    800003f2:	0047979b          	slliw	a5,a5,0x4
    r->coeffs[2 * i + 0] = (int16_t)(t0 | (((uint16_t)t1 << 8) & 0xFFF));
    800003f6:	00676733          	or	a4,a4,t1
    r->coeffs[2 * i + 1] = (int16_t)((t1 >> 4) | (t2 << 4));
    800003fa:	8fd1                	or	a5,a5,a2
    r->coeffs[2 * i + 0] = (int16_t)(t0 | (((uint16_t)t1 << 8) & 0xFFF));
    800003fc:	00e69023          	sh	a4,0(a3)
    r->coeffs[2 * i + 1] = (int16_t)((t1 >> 4) | (t2 << 4));
    80000400:	00f69123          	sh	a5,2(a3)
  for (i = 0; i < MLKEM_N / 2; i++)
    80000404:	058d                	addi	a1,a1,3
    80000406:	0691                	addi	a3,a3,4
    80000408:	fcb81ae3          	bne	a6,a1,800003dc <mlkem_polyvec_frombytes+0xa>
    8000040c:	20050513          	addi	a0,a0,512
    80000410:	00a89363          	bne	a7,a0,80000416 <mlkem_polyvec_frombytes+0x44>
  {
    mlk_poly_frombytes(&r->vec[i], a + i * MLKEM_POLYBYTES);
  }

  mlk_assert_bound_2d(r->vec, MLKEM_K, MLKEM_N, 0, MLKEM_UINT12_LIMIT);
}
    80000414:	8082                	ret
  for (i = 0; i < MLKEM_K; i++)
    80000416:	85c2                	mv	a1,a6
    80000418:	bf7d                	j	800003d6 <mlkem_polyvec_frombytes+0x4>

000000008000041a <mlk_polyvec_basemul_acc_montgomery_cached_c>:
  /* check-magic: 62209 == unsigned_mod(pow(MLKEM_Q, -1, 2^16), 2^16) */
  const uint32_t QINV = 62209;

  /* Compute a*q^{-1} mod 2^16 in unsigned representatives. */
  const uint16_t a_reduced = mlk_cast_int32_to_uint16(a);
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    8000041a:	737d                	lui	t1,0xfffff
  int32_t r;

  mlk_assert(a < +(INT32_MAX - (((int32_t)1 << 15) * MLKEM_Q)) &&
             a > -(INT32_MAX - (((int32_t)1 << 15) * MLKEM_Q)));

  r = a - ((int32_t)t * MLKEM_Q);
    8000041c:	78fd                	lui	a7,0xfffff
    8000041e:	20058e13          	addi	t3,a1,512
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000422:	3013031b          	addiw	t1,t1,769 # fffffffffffff301 <_stack_start+0xffffffff7ffe7141>
  r = a - ((int32_t)t * MLKEM_Q);
    80000426:	2ff8889b          	addiw	a7,a7,767 # fffffffffffff2ff <_stack_start+0xffffffff7ffe713f>
         t[0] >= - ((int32_t) k * 2 * MLKEM_UINT12_LIMIT * 32768) &&
         t[1] <=   ((int32_t) k * 2 * MLKEM_UINT12_LIMIT * 32768) &&
         t[1] >= - ((int32_t) k * 2 * MLKEM_UINT12_LIMIT * 32768))
      decreases(MLKEM_K - k))
    {
      t[0] += (int32_t)a->vec[k].coeffs[2 * i + 1] * b_cache->vec[k].coeffs[i];
    8000042a:	00259283          	lh	t0,2(a1)
      t[0] += (int32_t)a->vec[k].coeffs[2 * i] * b->vec[k].coeffs[2 * i];
    8000042e:	00059383          	lh	t2,0(a1)
    80000432:	00061783          	lh	a5,0(a2)
      t[0] += (int32_t)a->vec[k].coeffs[2 * i + 1] * b_cache->vec[k].coeffs[i];
    80000436:	00069803          	lh	a6,0(a3)
    8000043a:	20259703          	lh	a4,514(a1)
      t[0] += (int32_t)a->vec[k].coeffs[2 * i] * b->vec[k].coeffs[2 * i];
    8000043e:	02778ebb          	mulw	t4,a5,t2
    80000442:	20059f83          	lh	t6,512(a1)
    80000446:	20061f03          	lh	t5,512(a2)
  for (i = 0; i < MLKEM_N / 2; i++)
    8000044a:	0591                	addi	a1,a1,4
    8000044c:	0689                	addi	a3,a3,2
    8000044e:	0611                	addi	a2,a2,4
    80000450:	0511                	addi	a0,a0,4
      t[0] += (int32_t)a->vec[k].coeffs[2 * i + 1] * b_cache->vec[k].coeffs[i];
    80000452:	0258083b          	mulw	a6,a6,t0
      t[1] += (int32_t)a->vec[k].coeffs[2 * i] * b->vec[k].coeffs[2 * i + 1];
      t[1] += (int32_t)a->vec[k].coeffs[2 * i + 1] * b->vec[k].coeffs[2 * i];
    80000456:	025787bb          	mulw	a5,a5,t0
      t[0] += (int32_t)a->vec[k].coeffs[2 * i] * b->vec[k].coeffs[2 * i];
    8000045a:	010e8ebb          	addw	t4,t4,a6
      t[0] += (int32_t)a->vec[k].coeffs[2 * i + 1] * b_cache->vec[k].coeffs[i];
    8000045e:	0fe69803          	lh	a6,254(a3)
    80000462:	02e8083b          	mulw	a6,a6,a4
      t[1] += (int32_t)a->vec[k].coeffs[2 * i + 1] * b->vec[k].coeffs[2 * i];
    80000466:	03e7073b          	mulw	a4,a4,t5
      t[0] += (int32_t)a->vec[k].coeffs[2 * i + 1] * b_cache->vec[k].coeffs[i];
    8000046a:	01d8083b          	addw	a6,a6,t4
      t[0] += (int32_t)a->vec[k].coeffs[2 * i] * b->vec[k].coeffs[2 * i];
    8000046e:	03ef8ebb          	mulw	t4,t6,t5
    80000472:	010e8ebb          	addw	t4,t4,a6
      t[1] += (int32_t)a->vec[k].coeffs[2 * i] * b->vec[k].coeffs[2 * i + 1];
    80000476:	ffe61803          	lh	a6,-2(a2)
    8000047a:	0278083b          	mulw	a6,a6,t2
      t[1] += (int32_t)a->vec[k].coeffs[2 * i + 1] * b->vec[k].coeffs[2 * i];
    8000047e:	010787bb          	addw	a5,a5,a6
      t[1] += (int32_t)a->vec[k].coeffs[2 * i] * b->vec[k].coeffs[2 * i + 1];
    80000482:	1fe61803          	lh	a6,510(a2)
    80000486:	03f8083b          	mulw	a6,a6,t6
    8000048a:	00f807bb          	addw	a5,a6,a5
      t[1] += (int32_t)a->vec[k].coeffs[2 * i + 1] * b->vec[k].coeffs[2 * i];
    8000048e:	9f3d                	addw	a4,a4,a5
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000490:	03d307bb          	mulw	a5,t1,t4
  r = a - ((int32_t)t * MLKEM_Q);
    80000494:	0107979b          	slliw	a5,a5,0x10
    80000498:	4107d79b          	sraiw	a5,a5,0x10
    8000049c:	031787bb          	mulw	a5,a5,a7
    800004a0:	01d787bb          	addw	a5,a5,t4
  /*
   * PORTABILITY: Right-shift on a signed integer is, strictly-speaking,
   * implementation-defined for negative left argument. Here,
   * we assume it's sign-preserving "arithmetic" shift right. (C99 6.5.7 (5))
   */
  r = r >> 16;
    800004a4:	4107d79b          	sraiw	a5,a5,0x10
   *                   <= ceil(|a| / 2^16 + MLKEM_Q / 2)
   *                   <= ceil(|a| / 2^16) + (MLKEM_Q + 1) / 2
   *
   * (Note that |a >> n| = ceil(|a| / 2^16) for negative a)
   */
  return (int16_t)r;
    800004a8:	fef51e23          	sh	a5,-4(a0)
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    800004ac:	02e307bb          	mulw	a5,t1,a4
  r = a - ((int32_t)t * MLKEM_Q);
    800004b0:	0107979b          	slliw	a5,a5,0x10
    800004b4:	4107d79b          	sraiw	a5,a5,0x10
    800004b8:	031787bb          	mulw	a5,a5,a7
    800004bc:	9fb9                	addw	a5,a5,a4
  r = r >> 16;
    800004be:	4107d79b          	sraiw	a5,a5,0x10
  return (int16_t)r;
    800004c2:	fef51f23          	sh	a5,-2(a0)
  for (i = 0; i < MLKEM_N / 2; i++)
    800004c6:	f6be12e3          	bne	t3,a1,8000042a <mlk_polyvec_basemul_acc_montgomery_cached_c+0x10>
    }
    r->coeffs[2 * i + 0] = mlk_montgomery_reduce(t[0]);
    r->coeffs[2 * i + 1] = mlk_montgomery_reduce(t[1]);
  }
}
    800004ca:	8082                	ret

00000000800004cc <mlkem_poly_cbd2>:
    invariant(array_abs_bound(r->coeffs, 0, 8 * i, 3))
    decreases(MLKEM_N / 8 - i))
  {
    unsigned j;
    uint32_t t = mlk_load32_littleendian(buf + 4 * i);
    uint32_t d = t & 0x55555555;
    800004cc:	555558b7          	lui	a7,0x55555
{
    800004d0:	4801                	li	a6,0
    uint32_t d = t & 0x55555555;
    800004d2:	55588893          	addi	a7,a7,1365 # 55555555 <_stack_size+0x55545555>
    d += (t >> 1) & 0x55555555;

    for (j = 0; j < 8; j++)
    800004d6:	02000f13          	li	t5,32
  for (i = 0; i < MLKEM_N / 8; i++)
    800004da:	10000e93          	li	t4,256
  r |= (uint32_t)x[3] << 24;
    800004de:	419c                	lw	a5,0(a1)
    d += (t >> 1) & 0x55555555;
    800004e0:	8342                	mv	t1,a6
    uint32_t d = t & 0x55555555;
    800004e2:	0117f733          	and	a4,a5,a7
    d += (t >> 1) & 0x55555555;
    800004e6:	0017d79b          	srliw	a5,a5,0x1
    800004ea:	0117f7b3          	and	a5,a5,a7
    800004ee:	9fb9                	addw	a5,a5,a4
    800004f0:	4701                	li	a4,0
      decreases(8 - j))
    {
      /* Safety: The & 0x3 masks each value to 2 bits (range [0, 3]), so the
       * truncation and subsequent subtraction in int16_t is lossless. */
      const int16_t a = (int16_t)((d >> (4 * j + 0)) & 0x3);
      const int16_t b = (int16_t)((d >> (4 * j + 2)) & 0x3);
    800004f2:	0027061b          	addiw	a2,a4,2
      const int16_t a = (int16_t)((d >> (4 * j + 0)) & 0x3);
    800004f6:	00e7d6bb          	srlw	a3,a5,a4
      const int16_t b = (int16_t)((d >> (4 * j + 2)) & 0x3);
    800004fa:	00c7d63b          	srlw	a2,a5,a2
      r->coeffs[8 * i + j] = (int16_t)(a - b);
    800004fe:	00131e13          	slli	t3,t1,0x1
      const int16_t a = (int16_t)((d >> (4 * j + 0)) & 0x3);
    80000502:	8a8d                	andi	a3,a3,3
      const int16_t b = (int16_t)((d >> (4 * j + 2)) & 0x3);
    80000504:	8a0d                	andi	a2,a2,3
      r->coeffs[8 * i + j] = (int16_t)(a - b);
    80000506:	9e2a                	add	t3,t3,a0
    80000508:	9e91                	subw	a3,a3,a2
    8000050a:	00de1023          	sh	a3,0(t3)
    for (j = 0; j < 8; j++)
    8000050e:	2711                	addiw	a4,a4,4
    80000510:	2305                	addiw	t1,t1,1
    80000512:	ffe710e3          	bne	a4,t5,800004f2 <mlkem_poly_cbd2+0x26>
  for (i = 0; i < MLKEM_N / 8; i++)
    80000516:	2821                	addiw	a6,a6,8
    80000518:	0591                	addi	a1,a1,4
    8000051a:	fdd812e3          	bne	a6,t4,800004de <mlkem_poly_cbd2+0x12>
    }
  }
}
    8000051e:	8082                	ret

0000000080000520 <mlkem_poly_cbd3>:
    invariant(array_abs_bound(r->coeffs, 0, 4 * i, 4))
    decreases(MLKEM_N / 4 - i))
  {
    unsigned j;
    const uint32_t t = mlk_load24_littleendian(buf + 3 * i);
    uint32_t d = t & 0x00249249;
    80000520:	002496b7          	lui	a3,0x249
{
    80000524:	4881                	li	a7,0
    uint32_t d = t & 0x00249249;
    80000526:	24968693          	addi	a3,a3,585 # 249249 <_stack_size+0x239249>
    d += (t >> 1) & 0x00249249;
    d += (t >> 2) & 0x00249249;

    for (j = 0; j < 4; j++)
    8000052a:	4f61                	li	t5,24
  for (i = 0; i < MLKEM_N / 4; i++)
    8000052c:	10000e93          	li	t4,256
  r |= (uint32_t)x[1] << 8;
    80000530:	0015c703          	lbu	a4,1(a1)
    80000534:	0005c783          	lbu	a5,0(a1)
    d += (t >> 2) & 0x00249249;
    80000538:	8346                	mv	t1,a7
  r |= (uint32_t)x[1] << 8;
    8000053a:	0722                	slli	a4,a4,0x8
    8000053c:	8f5d                	or	a4,a4,a5
  r |= (uint32_t)x[2] << 16;
    8000053e:	0025c783          	lbu	a5,2(a1)
    80000542:	0107979b          	slliw	a5,a5,0x10
    80000546:	8fd9                	or	a5,a5,a4
    uint32_t d = t & 0x00249249;
    80000548:	00d7f633          	and	a2,a5,a3
    d += (t >> 1) & 0x00249249;
    8000054c:	0017d71b          	srliw	a4,a5,0x1
    d += (t >> 2) & 0x00249249;
    80000550:	0027d79b          	srliw	a5,a5,0x2
    d += (t >> 1) & 0x00249249;
    80000554:	8f75                	and	a4,a4,a3
    d += (t >> 2) & 0x00249249;
    80000556:	8ff5                	and	a5,a5,a3
    80000558:	9fb9                	addw	a5,a5,a4
    8000055a:	9fb1                	addw	a5,a5,a2
    8000055c:	4701                	li	a4,0
      decreases(4 - j))
    {
      /* Safety: The & 0x7 masks each value to 3 bits (range [0, 7]), so the
       * truncation and subsequent subtraction in int16_t is lossless. */
      const int16_t a = (int16_t)((d >> (6 * j + 0)) & 0x7);
      const int16_t b = (int16_t)((d >> (6 * j + 3)) & 0x7);
    8000055e:	0037081b          	addiw	a6,a4,3
      const int16_t a = (int16_t)((d >> (6 * j + 0)) & 0x7);
    80000562:	00e7d63b          	srlw	a2,a5,a4
      const int16_t b = (int16_t)((d >> (6 * j + 3)) & 0x7);
    80000566:	0107d83b          	srlw	a6,a5,a6
      r->coeffs[4 * i + j] = (int16_t)(a - b);
    8000056a:	00131e13          	slli	t3,t1,0x1
      const int16_t a = (int16_t)((d >> (6 * j + 0)) & 0x7);
    8000056e:	8a1d                	andi	a2,a2,7
      const int16_t b = (int16_t)((d >> (6 * j + 3)) & 0x7);
    80000570:	00787813          	andi	a6,a6,7
      r->coeffs[4 * i + j] = (int16_t)(a - b);
    80000574:	9e2a                	add	t3,t3,a0
    80000576:	4106063b          	subw	a2,a2,a6
    8000057a:	00ce1023          	sh	a2,0(t3)
    for (j = 0; j < 4; j++)
    8000057e:	2719                	addiw	a4,a4,6
    80000580:	2305                	addiw	t1,t1,1
    80000582:	fde71ee3          	bne	a4,t5,8000055e <mlkem_poly_cbd3+0x3e>
  for (i = 0; i < MLKEM_N / 4; i++)
    80000586:	2891                	addiw	a7,a7,4
    80000588:	058d                	addi	a1,a1,3
    8000058a:	fbd893e3          	bne	a7,t4,80000530 <mlkem_poly_cbd3+0x10>
    }
  }
}
    8000058e:	8082                	ret

0000000080000590 <mlk_keccakf1600_permute_c>:
  uint64_t Ema, Eme, Emi, Emo, Emu;
  uint64_t Esa, Ese, Esi, Eso, Esu;

  /* copyFromState(A, state) */
  Aba = state[0];
  Abe = state[1];
    80000590:	651c                	ld	a5,8(a0)
{
    80000592:	7151                	addi	sp,sp,-240
    80000594:	f5a2                	sd	s0,232(sp)
  Abe = state[1];
    80000596:	e43e                	sd	a5,8(sp)
  Abi = state[2];
    80000598:	691c                	ld	a5,16(a0)
{
    8000059a:	f1a6                	sd	s1,224(sp)
    8000059c:	edca                	sd	s2,216(sp)
  Abi = state[2];
    8000059e:	e83e                	sd	a5,16(sp)
  Abo = state[3];
  Abu = state[4];
    800005a0:	711c                	ld	a5,32(a0)
{
    800005a2:	e9ce                	sd	s3,208(sp)
    800005a4:	e5d2                	sd	s4,200(sp)
  Abu = state[4];
    800005a6:	ec3e                	sd	a5,24(sp)
  Aga = state[5];
    800005a8:	751c                	ld	a5,40(a0)
{
    800005aa:	ed6a                	sd	s10,152(sp)
  Aba = state[0];
    800005ac:	00053a03          	ld	s4,0(a0)
  Aga = state[5];
    800005b0:	f03e                	sd	a5,32(sp)
  Age = state[6];
  Agi = state[7];
  Ago = state[8];
    800005b2:	613c                	ld	a5,64(a0)
  Abo = state[3];
    800005b4:	6d0c                	ld	a1,24(a0)
  Age = state[6];
    800005b6:	03053983          	ld	s3,48(a0)
  Ago = state[8];
    800005ba:	f43e                	sd	a5,40(sp)
  Agu = state[9];
  Aka = state[10];
  Ake = state[11];
    800005bc:	6d3c                	ld	a5,88(a0)
  Agi = state[7];
    800005be:	03853903          	ld	s2,56(a0)
  Agu = state[9];
    800005c2:	6534                	ld	a3,72(a0)
  Ake = state[11];
    800005c4:	f83e                	sd	a5,48(sp)
  Aka = state[10];
    800005c6:	6924                	ld	s1,80(a0)
  Aki = state[12];
    800005c8:	7120                	ld	s0,96(a0)
{
    800005ca:	e1d6                	sd	s5,192(sp)
    800005cc:	fd5a                	sd	s6,184(sp)
    800005ce:	f95e                	sd	s7,176(sp)
    800005d0:	f562                	sd	s8,168(sp)
    800005d2:	f166                	sd	s9,160(sp)
    800005d4:	e96e                	sd	s11,144(sp)
  Ako = state[13];
    800005d6:	06853383          	ld	t2,104(a0)
  Aku = state[14];
    800005da:	793c                	ld	a5,112(a0)
  Ama = state[15];
  Ame = state[16];
    800005dc:	08053283          	ld	t0,128(a0)
  Ami = state[17];
    800005e0:	08853f83          	ld	t6,136(a0)
  Aku = state[14];
    800005e4:	fc3e                	sd	a5,56(sp)
  Ama = state[15];
    800005e6:	7d3c                	ld	a5,120(a0)
  Amo = state[18];
    800005e8:	09053f03          	ld	t5,144(a0)
  Amu = state[19];
    800005ec:	6d58                	ld	a4,152(a0)
  Asa = state[20];
    800005ee:	0a053e83          	ld	t4,160(a0)
  Ase = state[21];
    800005f2:	0a853d03          	ld	s10,168(a0)
  Asi = state[22];
    800005f6:	0b053e03          	ld	t3,176(a0)
  Aso = state[23];
    800005fa:	0b853303          	ld	t1,184(a0)
  Asu = state[24];
    800005fe:	6170                	ld	a2,192(a0)
  Ama = state[15];
    80000600:	e0be                	sd	a5,64(sp)

  for (round = 0; round < MLK_KECCAK_NROUNDS; round += 2)
    80000602:	00003797          	auipc	a5,0x3
    80000606:	d1e78793          	addi	a5,a5,-738 # 80003320 <mlk_KeccakF_RoundConstants>
    8000060a:	e03e                	sd	a5,0(sp)
  __loop__(invariant(round <= MLK_KECCAK_NROUNDS && round % 2 == 0)
           decreases(MLK_KECCAK_NROUNDS - round))
  {
    /* prepareTheta */
    BCa = Aba ^ Aga ^ Aka ^ Ama ^ Asa;
    8000060c:	7782                	ld	a5,32(sp)
    8000060e:	00fa4ab3          	xor	s5,s4,a5
    80000612:	6786                	ld	a5,64(sp)
    80000614:	009acab3          	xor	s5,s5,s1
    80000618:	00facab3          	xor	s5,s5,a5
    BCe = Abe ^ Age ^ Ake ^ Ame ^ Ase;
    8000061c:	67a2                	ld	a5,8(sp)
    BCa = Aba ^ Aga ^ Aka ^ Ama ^ Asa;
    8000061e:	01dacab3          	xor	s5,s5,t4
    BCe = Abe ^ Age ^ Ake ^ Ame ^ Ase;
    80000622:	0137ccb3          	xor	s9,a5,s3
    80000626:	77c2                	ld	a5,48(sp)
    80000628:	00fcccb3          	xor	s9,s9,a5
    BCi = Abi ^ Agi ^ Aki ^ Ami ^ Asi;
    8000062c:	67c2                	ld	a5,16(sp)
    BCe = Abe ^ Age ^ Ake ^ Ame ^ Ase;
    8000062e:	005cccb3          	xor	s9,s9,t0
    80000632:	01acccb3          	xor	s9,s9,s10
    BCi = Abi ^ Agi ^ Aki ^ Ami ^ Asi;
    80000636:	0127cc33          	xor	s8,a5,s2
    BCo = Abo ^ Ago ^ Ako ^ Amo ^ Aso;
    8000063a:	77a2                	ld	a5,40(sp)
    BCi = Abi ^ Agi ^ Aki ^ Ami ^ Asi;
    8000063c:	008c4c33          	xor	s8,s8,s0
    80000640:	01fc4c33          	xor	s8,s8,t6
    BCo = Abo ^ Ago ^ Ako ^ Amo ^ Aso;
    80000644:	00f5cbb3          	xor	s7,a1,a5
    BCu = Abu ^ Agu ^ Aku ^ Amu ^ Asu;
    80000648:	67e2                	ld	a5,24(sp)
    BCo = Abo ^ Ago ^ Ako ^ Amo ^ Aso;
    8000064a:	007bcbb3          	xor	s7,s7,t2
    BCi = Abi ^ Agi ^ Aki ^ Ami ^ Asi;
    8000064e:	01cc4c33          	xor	s8,s8,t3
    BCu = Abu ^ Agu ^ Aku ^ Amu ^ Asu;
    80000652:	00d7cb33          	xor	s6,a5,a3
    80000656:	77e2                	ld	a5,56(sp)
    BCo = Abo ^ Ago ^ Ako ^ Amo ^ Aso;
    80000658:	01ebcbb3          	xor	s7,s7,t5

    /* thetaRhoPiChiIotaPrepareTheta(round, A, E) */
    Da = BCu ^ MLK_KECCAK_ROL(BCe, 1);
    8000065c:	03fcd893          	srli	a7,s9,0x3f
    BCu = Abu ^ Agu ^ Aku ^ Amu ^ Asu;
    80000660:	00fb4b33          	xor	s6,s6,a5
    Da = BCu ^ MLK_KECCAK_ROL(BCe, 1);
    80000664:	001c9793          	slli	a5,s9,0x1
    BCo = Abo ^ Ago ^ Ako ^ Amo ^ Aso;
    80000668:	006bcbb3          	xor	s7,s7,t1
    Da = BCu ^ MLK_KECCAK_ROL(BCe, 1);
    8000066c:	98be                	add	a7,a7,a5
    De = BCa ^ MLK_KECCAK_ROL(BCi, 1);
    8000066e:	03fc5813          	srli	a6,s8,0x3f
    80000672:	001c1793          	slli	a5,s8,0x1
    Di = BCe ^ MLK_KECCAK_ROL(BCo, 1);
    80000676:	001b9d93          	slli	s11,s7,0x1
    BCu = Abu ^ Agu ^ Aku ^ Amu ^ Asu;
    8000067a:	00eb4b33          	xor	s6,s6,a4
    De = BCa ^ MLK_KECCAK_ROL(BCi, 1);
    8000067e:	983e                	add	a6,a6,a5
    Di = BCe ^ MLK_KECCAK_ROL(BCo, 1);
    80000680:	03fbd793          	srli	a5,s7,0x3f
    BCu = Abu ^ Agu ^ Aku ^ Amu ^ Asu;
    80000684:	00cb4b33          	xor	s6,s6,a2
    Di = BCe ^ MLK_KECCAK_ROL(BCo, 1);
    80000688:	97ee                	add	a5,a5,s11
    Da = BCu ^ MLK_KECCAK_ROL(BCe, 1);
    8000068a:	0168c8b3          	xor	a7,a7,s6
    De = BCa ^ MLK_KECCAK_ROL(BCi, 1);
    8000068e:	01584833          	xor	a6,a6,s5
    Di = BCe ^ MLK_KECCAK_ROL(BCo, 1);
    80000692:	0197c7b3          	xor	a5,a5,s9
    Do = BCi ^ MLK_KECCAK_ROL(BCu, 1);
    80000696:	03fb5c93          	srli	s9,s6,0x3f
    8000069a:	0b06                	slli	s6,s6,0x1
    Du = BCo ^ MLK_KECCAK_ROL(BCa, 1);

    Aba ^= Da;
    BCa = Aba;
    Age ^= De;
    8000069c:	013849b3          	xor	s3,a6,s3
    Do = BCi ^ MLK_KECCAK_ROL(BCu, 1);
    800006a0:	9cda                	add	s9,s9,s6
    Du = BCo ^ MLK_KECCAK_ROL(BCa, 1);
    800006a2:	03fadb13          	srli	s6,s5,0x3f
    800006a6:	0a86                	slli	s5,s5,0x1
    Do = BCi ^ MLK_KECCAK_ROL(BCu, 1);
    800006a8:	018cccb3          	xor	s9,s9,s8
    BCe = MLK_KECCAK_ROL(Age, 44);
    Aki ^= Di;
    800006ac:	8c3d                	xor	s0,s0,a5
    Du = BCo ^ MLK_KECCAK_ROL(BCa, 1);
    800006ae:	9ada                	add	s5,s5,s6
    BCe = MLK_KECCAK_ROL(Age, 44);
    800006b0:	0149db13          	srli	s6,s3,0x14
    800006b4:	19b2                	slli	s3,s3,0x2c
    Du = BCo ^ MLK_KECCAK_ROL(BCa, 1);
    800006b6:	017acab3          	xor	s5,s5,s7
    BCe = MLK_KECCAK_ROL(Age, 44);
    800006ba:	99da                	add	s3,s3,s6
    BCi = MLK_KECCAK_ROL(Aki, 43);
    Amo ^= Do;
    800006bc:	01eccf33          	xor	t5,s9,t5
    BCi = MLK_KECCAK_ROL(Aki, 43);
    800006c0:	01545b13          	srli	s6,s0,0x15
    800006c4:	142e                	slli	s0,s0,0x2b
    800006c6:	945a                	add	s0,s0,s6
    BCo = MLK_KECCAK_ROL(Amo, 21);
    Asu ^= Du;
    800006c8:	00cac633          	xor	a2,s5,a2
    BCo = MLK_KECCAK_ROL(Amo, 21);
    800006cc:	02bf5b13          	srli	s6,t5,0x2b
    800006d0:	0f56                	slli	t5,t5,0x15
    800006d2:	9f5a                	add	t5,t5,s6
    BCu = MLK_KECCAK_ROL(Asu, 14);
    800006d4:	03265b13          	srli	s6,a2,0x32
    800006d8:	063a                	slli	a2,a2,0xe
    800006da:	965a                	add	a2,a2,s6
    Eba = BCa ^ ((~BCe) & BCi);
    Eba ^= (uint64_t)mlk_KeccakF_RoundConstants[round];
    800006dc:	6b02                	ld	s6,0(sp)
    Aba ^= Da;
    800006de:	0148ca33          	xor	s4,a7,s4
    Eba = BCa ^ ((~BCe) & BCi);
    800006e2:	fff9cb93          	not	s7,s3
    Eba ^= (uint64_t)mlk_KeccakF_RoundConstants[round];
    800006e6:	000b3b03          	ld	s6,0(s6)
    Eba = BCa ^ ((~BCe) & BCi);
    800006ea:	008bfbb3          	and	s7,s7,s0
    Ebe = BCe ^ ((~BCi) & BCo);
    Ebi = BCi ^ ((~BCo) & BCu);
    Ebo = BCo ^ ((~BCu) & BCa);
    Ebu = BCu ^ ((~BCa) & BCe);

    Abo ^= Do;
    800006ee:	00bcc5b3          	xor	a1,s9,a1
    Eba ^= (uint64_t)mlk_KeccakF_RoundConstants[round];
    800006f2:	016a4b33          	xor	s6,s4,s6
    800006f6:	016bcbb3          	xor	s7,s7,s6
    Ebe = BCe ^ ((~BCi) & BCo);
    800006fa:	fff44b13          	not	s6,s0
    800006fe:	01eb7b33          	and	s6,s6,t5
    80000702:	013b4b33          	xor	s6,s6,s3
    80000706:	e4da                	sd	s6,72(sp)
    Ebi = BCi ^ ((~BCo) & BCu);
    80000708:	ffff4b13          	not	s6,t5
    8000070c:	00cb7b33          	and	s6,s6,a2
    80000710:	008b4b33          	xor	s6,s6,s0
    Ebo = BCo ^ ((~BCu) & BCa);
    80000714:	fff64413          	not	s0,a2
    80000718:	01447433          	and	s0,s0,s4
    Ebu = BCu ^ ((~BCa) & BCe);
    8000071c:	fffa4a13          	not	s4,s4
    80000720:	013a7a33          	and	s4,s4,s3
    80000724:	00ca4633          	xor	a2,s4,a2
    BCa = MLK_KECCAK_ROL(Abo, 28);
    Agu ^= Du;
    80000728:	00dac6b3          	xor	a3,s5,a3
    Ebu = BCu ^ ((~BCa) & BCe);
    8000072c:	e8b2                	sd	a2,80(sp)
    BCa = MLK_KECCAK_ROL(Abo, 28);
    8000072e:	0245d613          	srli	a2,a1,0x24
    80000732:	05f2                	slli	a1,a1,0x1c
    80000734:	95b2                	add	a1,a1,a2
    BCe = MLK_KECCAK_ROL(Agu, 20);
    Aka ^= Da;
    80000736:	0098c4b3          	xor	s1,a7,s1
    BCe = MLK_KECCAK_ROL(Agu, 20);
    8000073a:	02c6d613          	srli	a2,a3,0x2c
    8000073e:	06d2                	slli	a3,a3,0x14
    80000740:	96b2                	add	a3,a3,a2
    BCi = MLK_KECCAK_ROL(Aka, 3);
    Ame ^= De;
    80000742:	005842b3          	xor	t0,a6,t0
    BCi = MLK_KECCAK_ROL(Aka, 3);
    80000746:	03d4d613          	srli	a2,s1,0x3d
    8000074a:	048e                	slli	s1,s1,0x3
    8000074c:	94b2                	add	s1,s1,a2
    BCo = MLK_KECCAK_ROL(Ame, 45);
    Asi ^= Di;
    8000074e:	01c7ce33          	xor	t3,a5,t3
    BCo = MLK_KECCAK_ROL(Ame, 45);
    80000752:	0132d613          	srli	a2,t0,0x13
    80000756:	12b6                	slli	t0,t0,0x2d
    80000758:	92b2                	add	t0,t0,a2
    BCu = MLK_KECCAK_ROL(Asi, 61);
    8000075a:	003e5613          	srli	a2,t3,0x3
    8000075e:	1e76                	slli	t3,t3,0x3d
    80000760:	9e32                	add	t3,t3,a2
    Ega = BCa ^ ((~BCe) & BCi);
    80000762:	fff6c613          	not	a2,a3
    80000766:	8e65                	and	a2,a2,s1
    80000768:	8e2d                	xor	a2,a2,a1
    8000076a:	ecb2                	sd	a2,88(sp)
    Ege = BCe ^ ((~BCi) & BCo);
    Egi = BCi ^ ((~BCo) & BCu);
    8000076c:	fff2c613          	not	a2,t0
    80000770:	01c67633          	and	a2,a2,t3
    80000774:	8e25                	xor	a2,a2,s1
    Ebo = BCo ^ ((~BCu) & BCa);
    80000776:	01e44db3          	xor	s11,s0,t5
    Egi = BCi ^ ((~BCo) & BCu);
    8000077a:	f0b2                	sd	a2,96(sp)
    Ege = BCe ^ ((~BCi) & BCo);
    8000077c:	fff4cf13          	not	t5,s1
    Ego = BCo ^ ((~BCu) & BCa);
    80000780:	fffe4613          	not	a2,t3
    Ege = BCe ^ ((~BCi) & BCo);
    80000784:	005f7f33          	and	t5,t5,t0
    Ego = BCo ^ ((~BCu) & BCa);
    80000788:	8e6d                	and	a2,a2,a1
    Egu = BCu ^ ((~BCa) & BCe);
    8000078a:	fff5c593          	not	a1,a1
    Ege = BCe ^ ((~BCi) & BCo);
    8000078e:	00df4f33          	xor	t5,t5,a3
    Egu = BCu ^ ((~BCa) & BCe);
    80000792:	8df5                	and	a1,a1,a3

    Abe ^= De;
    80000794:	66a2                	ld	a3,8(sp)
    Ego = BCo ^ ((~BCu) & BCa);
    80000796:	00564633          	xor	a2,a2,t0
    BCa = MLK_KECCAK_ROL(Abe, 1);
    Agi ^= Di;
    8000079a:	0127c933          	xor	s2,a5,s2
    Abe ^= De;
    8000079e:	00d846b3          	xor	a3,a6,a3
    Ego = BCo ^ ((~BCu) & BCa);
    800007a2:	f4b2                	sd	a2,104(sp)
    BCa = MLK_KECCAK_ROL(Abe, 1);
    800007a4:	03f6d613          	srli	a2,a3,0x3f
    800007a8:	0686                	slli	a3,a3,0x1
    800007aa:	96b2                	add	a3,a3,a2
    BCe = MLK_KECCAK_ROL(Agi, 6);
    Ako ^= Do;
    800007ac:	007cc3b3          	xor	t2,s9,t2
    BCe = MLK_KECCAK_ROL(Agi, 6);
    800007b0:	03a95613          	srli	a2,s2,0x3a
    800007b4:	091a                	slli	s2,s2,0x6
    800007b6:	9932                	add	s2,s2,a2
    BCi = MLK_KECCAK_ROL(Ako, 25);
    Amu ^= Du;
    800007b8:	00eac733          	xor	a4,s5,a4
    BCi = MLK_KECCAK_ROL(Ako, 25);
    800007bc:	0273d613          	srli	a2,t2,0x27
    800007c0:	03e6                	slli	t2,t2,0x19
    800007c2:	93b2                	add	t2,t2,a2
    BCo = MLK_KECCAK_ROL(Amu, 8);
    Asa ^= Da;
    800007c4:	01d8ceb3          	xor	t4,a7,t4
    BCo = MLK_KECCAK_ROL(Amu, 8);
    800007c8:	03875613          	srli	a2,a4,0x38
    800007cc:	0722                	slli	a4,a4,0x8
    800007ce:	9732                	add	a4,a4,a2
    BCu = MLK_KECCAK_ROL(Asa, 18);
    800007d0:	02eed613          	srli	a2,t4,0x2e
    800007d4:	0eca                	slli	t4,t4,0x12
    800007d6:	9eb2                	add	t4,t4,a2
    Eka = BCa ^ ((~BCe) & BCi);
    Eke = BCe ^ ((~BCi) & BCo);
    800007d8:	fff3c613          	not	a2,t2
    800007dc:	8e79                	and	a2,a2,a4
    Egu = BCu ^ ((~BCa) & BCe);
    800007de:	01c5c2b3          	xor	t0,a1,t3
    Eke = BCe ^ ((~BCi) & BCo);
    800007e2:	01264633          	xor	a2,a2,s2
    Eka = BCa ^ ((~BCe) & BCi);
    800007e6:	fff94e13          	not	t3,s2
    Eke = BCe ^ ((~BCi) & BCo);
    800007ea:	f8b2                	sd	a2,112(sp)
    Eka = BCa ^ ((~BCe) & BCi);
    800007ec:	007e7e33          	and	t3,t3,t2
    Eki = BCi ^ ((~BCo) & BCu);
    Eko = BCo ^ ((~BCu) & BCa);
    800007f0:	fffec613          	not	a2,t4
    Eka = BCa ^ ((~BCe) & BCi);
    800007f4:	00de4e33          	xor	t3,t3,a3
    Eko = BCo ^ ((~BCu) & BCa);
    800007f8:	8e75                	and	a2,a2,a3
    Eku = BCu ^ ((~BCa) & BCe);
    800007fa:	fff6c693          	not	a3,a3
    800007fe:	0126f6b3          	and	a3,a3,s2
    Eko = BCo ^ ((~BCu) & BCa);
    80000802:	00e644b3          	xor	s1,a2,a4
    Eki = BCi ^ ((~BCo) & BCu);
    80000806:	fff74593          	not	a1,a4
    Eku = BCu ^ ((~BCa) & BCe);
    8000080a:	01d6c733          	xor	a4,a3,t4
    8000080e:	fcba                	sd	a4,120(sp)

    Abu ^= Du;
    80000810:	6762                	ld	a4,24(sp)
    BCa = MLK_KECCAK_ROL(Abu, 27);
    Aga ^= Da;
    BCe = MLK_KECCAK_ROL(Aga, 36);
    Ake ^= De;
    BCi = MLK_KECCAK_ROL(Ake, 10);
    Ami ^= Di;
    80000812:	01f7cfb3          	xor	t6,a5,t6
    Eki = BCi ^ ((~BCo) & BCu);
    80000816:	01d5f5b3          	and	a1,a1,t4
    Abu ^= Du;
    8000081a:	00eac633          	xor	a2,s5,a4
    BCa = MLK_KECCAK_ROL(Abu, 27);
    8000081e:	02565713          	srli	a4,a2,0x25
    80000822:	066e                	slli	a2,a2,0x1b
    80000824:	963a                	add	a2,a2,a4
    Aga ^= Da;
    80000826:	7702                	ld	a4,32(sp)
    BCo = MLK_KECCAK_ROL(Ami, 15);
    Aso ^= Do;
    80000828:	006cc333          	xor	t1,s9,t1
    Eki = BCi ^ ((~BCo) & BCu);
    8000082c:	0075c5b3          	xor	a1,a1,t2
    Aga ^= Da;
    80000830:	00e8c733          	xor	a4,a7,a4
    BCe = MLK_KECCAK_ROL(Aga, 36);
    80000834:	01c75693          	srli	a3,a4,0x1c
    80000838:	1712                	slli	a4,a4,0x24
    8000083a:	9736                	add	a4,a4,a3
    Ake ^= De;
    8000083c:	76c2                	ld	a3,48(sp)
    8000083e:	00d846b3          	xor	a3,a6,a3
    BCi = MLK_KECCAK_ROL(Ake, 10);
    80000842:	0366de93          	srli	t4,a3,0x36
    80000846:	06aa                	slli	a3,a3,0xa
    80000848:	96f6                	add	a3,a3,t4
    BCo = MLK_KECCAK_ROL(Ami, 15);
    8000084a:	031fde93          	srli	t4,t6,0x31
    8000084e:	0fbe                	slli	t6,t6,0xf
    80000850:	9ff6                	add	t6,t6,t4
    BCu = MLK_KECCAK_ROL(Aso, 56);
    80000852:	00835e93          	srli	t4,t1,0x8
    80000856:	1362                	slli	t1,t1,0x38
    80000858:	9376                	add	t1,t1,t4
    Ema = BCa ^ ((~BCe) & BCi);
    8000085a:	fff74e93          	not	t4,a4
    8000085e:	00defeb3          	and	t4,t4,a3
    80000862:	00cec433          	xor	s0,t4,a2
    80000866:	e122                	sd	s0,128(sp)
    Eme = BCe ^ ((~BCi) & BCo);
    80000868:	fff6c393          	not	t2,a3
    Emi = BCi ^ ((~BCo) & BCu);
    Emo = BCo ^ ((~BCu) & BCa);
    8000086c:	fff34413          	not	s0,t1
    Eme = BCe ^ ((~BCi) & BCo);
    80000870:	01f3f3b3          	and	t2,t2,t6
    Emo = BCo ^ ((~BCu) & BCa);
    80000874:	8c71                	and	s0,s0,a2
    Emu = BCu ^ ((~BCa) & BCe);
    80000876:	fff64613          	not	a2,a2
    Eme = BCe ^ ((~BCi) & BCo);
    8000087a:	00e3c3b3          	xor	t2,t2,a4
    Emu = BCu ^ ((~BCa) & BCe);
    8000087e:	8e79                	and	a2,a2,a4

    Abi ^= Di;
    80000880:	6742                	ld	a4,16(sp)
    BCe = MLK_KECCAK_ROL(Ago, 55);
    Aku ^= Du;
    BCi = MLK_KECCAK_ROL(Aku, 39);
    Ama ^= Da;
    BCo = MLK_KECCAK_ROL(Ama, 41);
    Ase ^= De;
    80000882:	01a84833          	xor	a6,a6,s10
    Emo = BCo ^ ((~BCu) & BCa);
    80000886:	01f44433          	xor	s0,s0,t6
    Abi ^= Di;
    8000088a:	8fb9                	xor	a5,a5,a4
    BCa = MLK_KECCAK_ROL(Abi, 62);
    8000088c:	0027d713          	srli	a4,a5,0x2
    80000890:	17fa                	slli	a5,a5,0x3e
    80000892:	97ba                	add	a5,a5,a4
    Ago ^= Do;
    80000894:	7722                	ld	a4,40(sp)
    Emi = BCi ^ ((~BCo) & BCu);
    80000896:	ffffce93          	not	t4,t6
    8000089a:	006efeb3          	and	t4,t4,t1
    Ago ^= Do;
    8000089e:	00ecccb3          	xor	s9,s9,a4
    BCe = MLK_KECCAK_ROL(Ago, 55);
    800008a2:	009cd713          	srli	a4,s9,0x9
    800008a6:	1cde                	slli	s9,s9,0x37
    800008a8:	9cba                	add	s9,s9,a4
    Aku ^= Du;
    800008aa:	7762                	ld	a4,56(sp)
    BCu = MLK_KECCAK_ROL(Ase, 2);
    Esa = BCa ^ ((~BCe) & BCi);
    800008ac:	fffccf93          	not	t6,s9
    Emi = BCi ^ ((~BCo) & BCu);
    800008b0:	00dec6b3          	xor	a3,t4,a3
    Aku ^= Du;
    800008b4:	00eacab3          	xor	s5,s5,a4
    BCi = MLK_KECCAK_ROL(Aku, 39);
    800008b8:	019ad713          	srli	a4,s5,0x19
    800008bc:	1a9e                	slli	s5,s5,0x27
    800008be:	9aba                	add	s5,s5,a4
    Ama ^= Da;
    800008c0:	6706                	ld	a4,64(sp)
    Esa = BCa ^ ((~BCe) & BCi);
    800008c2:	015fffb3          	and	t6,t6,s5
    800008c6:	00ffcfb3          	xor	t6,t6,a5
    Ama ^= Da;
    800008ca:	00e8c8b3          	xor	a7,a7,a4
    BCo = MLK_KECCAK_ROL(Ama, 41);
    800008ce:	0178d713          	srli	a4,a7,0x17
    800008d2:	18a6                	slli	a7,a7,0x29
    800008d4:	98ba                	add	a7,a7,a4
    BCu = MLK_KECCAK_ROL(Ase, 2);
    800008d6:	03e85713          	srli	a4,a6,0x3e
    800008da:	080a                	slli	a6,a6,0x2
    800008dc:	983a                	add	a6,a6,a4
    Ese = BCe ^ ((~BCi) & BCo);
    800008de:	fffac713          	not	a4,s5
    800008e2:	01177733          	and	a4,a4,a7
    800008e6:	01974c33          	xor	s8,a4,s9
    Esi = BCi ^ ((~BCo) & BCu);
    Eso = BCo ^ ((~BCu) & BCa);
    800008ea:	fff84713          	not	a4,a6
    800008ee:	8f7d                	and	a4,a4,a5
    Esu = BCu ^ ((~BCa) & BCe);
    800008f0:	fff7c793          	not	a5,a5
    800008f4:	0197f7b3          	and	a5,a5,s9
    800008f8:	0107c933          	xor	s2,a5,a6

    /* prepareTheta */
    BCa = Eba ^ Ega ^ Eka ^ Ema ^ Esa;
    800008fc:	67e6                	ld	a5,88(sp)
    Emi = BCi ^ ((~BCo) & BCu);
    800008fe:	e536                	sd	a3,136(sp)
    Esi = BCi ^ ((~BCo) & BCu);
    80000900:	fff8c693          	not	a3,a7
    BCa = Eba ^ Ega ^ Eka ^ Ema ^ Esa;
    80000904:	00fbc9b3          	xor	s3,s7,a5
    80000908:	678a                	ld	a5,128(sp)
    8000090a:	01c9c9b3          	xor	s3,s3,t3
    Esi = BCi ^ ((~BCo) & BCu);
    8000090e:	0106f6b3          	and	a3,a3,a6
    BCa = Eba ^ Ega ^ Eka ^ Ema ^ Esa;
    80000912:	00f9c9b3          	xor	s3,s3,a5
    BCe = Ebe ^ Ege ^ Eke ^ Eme ^ Ese;
    80000916:	67a6                	ld	a5,72(sp)
    Esi = BCi ^ ((~BCo) & BCu);
    80000918:	0156c6b3          	xor	a3,a3,s5
    Emu = BCu ^ ((~BCa) & BCe);
    8000091c:	00664633          	xor	a2,a2,t1
    BCe = Ebe ^ Ege ^ Eke ^ Eme ^ Ese;
    80000920:	01e7c833          	xor	a6,a5,t5
    80000924:	77c6                	ld	a5,112(sp)
    Eso = BCo ^ ((~BCu) & BCa);
    80000926:	01174733          	xor	a4,a4,a7
    BCa = Eba ^ Ega ^ Eka ^ Ema ^ Esa;
    8000092a:	01f9c9b3          	xor	s3,s3,t6
    BCe = Ebe ^ Ege ^ Eke ^ Eme ^ Ese;
    8000092e:	00f84833          	xor	a6,a6,a5
    BCi = Ebi ^ Egi ^ Eki ^ Emi ^ Esi;
    80000932:	7786                	ld	a5,96(sp)
    BCe = Ebe ^ Ege ^ Eke ^ Eme ^ Ese;
    80000934:	00784833          	xor	a6,a6,t2
    80000938:	01884833          	xor	a6,a6,s8
    BCi = Ebi ^ Egi ^ Eki ^ Emi ^ Esi;
    8000093c:	00fb4ab3          	xor	s5,s6,a5
    80000940:	67aa                	ld	a5,136(sp)
    80000942:	00bacab3          	xor	s5,s5,a1
    BCo = Ebo ^ Ego ^ Eko ^ Emo ^ Eso;
    BCu = Ebu ^ Egu ^ Eku ^ Emu ^ Esu;

    /* thetaRhoPiChiIotaPrepareTheta(round+1, E, A) */
    Da = BCu ^ MLK_KECCAK_ROL(BCe, 1);
    80000946:	03f85893          	srli	a7,a6,0x3f
    BCi = Ebi ^ Egi ^ Eki ^ Emi ^ Esi;
    8000094a:	00facab3          	xor	s5,s5,a5
    BCo = Ebo ^ Ego ^ Eko ^ Emo ^ Eso;
    8000094e:	77a6                	ld	a5,104(sp)
    BCi = Ebi ^ Egi ^ Eki ^ Emi ^ Esi;
    80000950:	00dacab3          	xor	s5,s5,a3
    De = BCa ^ MLK_KECCAK_ROL(BCi, 1);
    80000954:	03fade93          	srli	t4,s5,0x3f
    BCo = Ebo ^ Ego ^ Eko ^ Emo ^ Eso;
    80000958:	00fdca33          	xor	s4,s11,a5
    BCu = Ebu ^ Egu ^ Eku ^ Emu ^ Esu;
    8000095c:	77e6                	ld	a5,120(sp)
    BCo = Ebo ^ Ego ^ Eko ^ Emo ^ Eso;
    8000095e:	009a4a33          	xor	s4,s4,s1
    80000962:	008a4a33          	xor	s4,s4,s0
    BCu = Ebu ^ Egu ^ Eku ^ Emu ^ Esu;
    80000966:	00f2c333          	xor	t1,t0,a5
    8000096a:	67c6                	ld	a5,80(sp)
    BCo = Ebo ^ Ego ^ Eko ^ Emo ^ Eso;
    8000096c:	00ea4a33          	xor	s4,s4,a4
    Di = BCe ^ MLK_KECCAK_ROL(BCo, 1);
    80000970:	001a1c93          	slli	s9,s4,0x1
    BCu = Ebu ^ Egu ^ Eku ^ Emu ^ Esu;
    80000974:	00f34333          	xor	t1,t1,a5
    Da = BCu ^ MLK_KECCAK_ROL(BCe, 1);
    80000978:	00181793          	slli	a5,a6,0x1
    8000097c:	98be                	add	a7,a7,a5
    De = BCa ^ MLK_KECCAK_ROL(BCi, 1);
    8000097e:	001a9793          	slli	a5,s5,0x1
    BCu = Ebu ^ Egu ^ Eku ^ Emu ^ Esu;
    80000982:	00c34333          	xor	t1,t1,a2
    De = BCa ^ MLK_KECCAK_ROL(BCi, 1);
    80000986:	9ebe                	add	t4,t4,a5
    Di = BCe ^ MLK_KECCAK_ROL(BCo, 1);
    80000988:	03fa5793          	srli	a5,s4,0x3f
    BCu = Ebu ^ Egu ^ Eku ^ Emu ^ Esu;
    8000098c:	01234333          	xor	t1,t1,s2
    Di = BCe ^ MLK_KECCAK_ROL(BCo, 1);
    80000990:	97e6                	add	a5,a5,s9
    Da = BCu ^ MLK_KECCAK_ROL(BCe, 1);
    80000992:	0068c8b3          	xor	a7,a7,t1
    Di = BCe ^ MLK_KECCAK_ROL(BCo, 1);
    80000996:	0107c7b3          	xor	a5,a5,a6
    Do = BCi ^ MLK_KECCAK_ROL(BCu, 1);
    8000099a:	03f35813          	srli	a6,t1,0x3f
    8000099e:	0306                	slli	t1,t1,0x1
    De = BCa ^ MLK_KECCAK_ROL(BCi, 1);
    800009a0:	013eceb3          	xor	t4,t4,s3
    Do = BCi ^ MLK_KECCAK_ROL(BCu, 1);
    800009a4:	981a                	add	a6,a6,t1
    Du = BCo ^ MLK_KECCAK_ROL(BCa, 1);
    800009a6:	03f9d313          	srli	t1,s3,0x3f
    800009aa:	0986                	slli	s3,s3,0x1
    Do = BCi ^ MLK_KECCAK_ROL(BCu, 1);
    800009ac:	01584833          	xor	a6,a6,s5

    Eba ^= Da;
    BCa = Eba;
    Ege ^= De;
    800009b0:	01df4f33          	xor	t5,t5,t4
    Emo ^= Do;
    BCo = MLK_KECCAK_ROL(Emo, 21);
    Esu ^= Du;
    BCu = MLK_KECCAK_ROL(Esu, 14);
    Aba = BCa ^ ((~BCe) & BCi);
    Aba ^= (uint64_t)mlk_KeccakF_RoundConstants[round + 1];
    800009b4:	6a82                	ld	s5,0(sp)
    Du = BCo ^ MLK_KECCAK_ROL(BCa, 1);
    800009b6:	934e                	add	t1,t1,s3
    800009b8:	01434333          	xor	t1,t1,s4
    Eki ^= Di;
    800009bc:	8dbd                	xor	a1,a1,a5
    BCe = MLK_KECCAK_ROL(Ege, 44);
    800009be:	014f5a13          	srli	s4,t5,0x14
    800009c2:	1f32                	slli	t5,t5,0x2c
    800009c4:	9f52                	add	t5,t5,s4
    Emo ^= Do;
    800009c6:	01044433          	xor	s0,s0,a6
    BCi = MLK_KECCAK_ROL(Eki, 43);
    800009ca:	0155da13          	srli	s4,a1,0x15
    800009ce:	15ae                	slli	a1,a1,0x2b
    800009d0:	95d2                	add	a1,a1,s4
    Esu ^= Du;
    800009d2:	00694933          	xor	s2,s2,t1
    BCo = MLK_KECCAK_ROL(Emo, 21);
    800009d6:	02b45a13          	srli	s4,s0,0x2b
    Aba ^= (uint64_t)mlk_KeccakF_RoundConstants[round + 1];
    800009da:	008aba83          	ld	s5,8(s5)
    BCo = MLK_KECCAK_ROL(Emo, 21);
    800009de:	0456                	slli	s0,s0,0x15
    800009e0:	9452                	add	s0,s0,s4
    BCu = MLK_KECCAK_ROL(Esu, 14);
    800009e2:	03295a13          	srli	s4,s2,0x32
    800009e6:	093a                	slli	s2,s2,0xe
    800009e8:	9952                	add	s2,s2,s4
    Eba ^= Da;
    800009ea:	011bc9b3          	xor	s3,s7,a7
    Aba = BCa ^ ((~BCe) & BCi);
    800009ee:	ffff4a13          	not	s4,t5
    Aba ^= (uint64_t)mlk_KeccakF_RoundConstants[round + 1];
    800009f2:	0159cab3          	xor	s5,s3,s5
    Aba = BCa ^ ((~BCe) & BCi);
    800009f6:	00ba7a33          	and	s4,s4,a1
    Aba ^= (uint64_t)mlk_KeccakF_RoundConstants[round + 1];
    800009fa:	015a4a33          	xor	s4,s4,s5
    Abe = BCe ^ ((~BCi) & BCo);
    800009fe:	fff5ca93          	not	s5,a1
    80000a02:	008afab3          	and	s5,s5,s0
    80000a06:	01eacab3          	xor	s5,s5,t5
    80000a0a:	e456                	sd	s5,8(sp)
    Abi = BCi ^ ((~BCo) & BCu);
    80000a0c:	fff44a93          	not	s5,s0
    80000a10:	012afab3          	and	s5,s5,s2
    80000a14:	00bac5b3          	xor	a1,s5,a1
    80000a18:	e82e                	sd	a1,16(sp)
    Abo = BCo ^ ((~BCu) & BCa);
    80000a1a:	fff94593          	not	a1,s2
    Abu = BCu ^ ((~BCa) & BCe);

    Ebo ^= Do;
    80000a1e:	010dcdb3          	xor	s11,s11,a6
    Abo = BCo ^ ((~BCu) & BCa);
    80000a22:	0135f5b3          	and	a1,a1,s3
    Abu = BCu ^ ((~BCa) & BCe);
    80000a26:	fff9c993          	not	s3,s3
    80000a2a:	01e9f9b3          	and	s3,s3,t5
    BCa = MLK_KECCAK_ROL(Ebo, 28);
    Egu ^= Du;
    80000a2e:	0062c2b3          	xor	t0,t0,t1
    BCa = MLK_KECCAK_ROL(Ebo, 28);
    80000a32:	024ddf13          	srli	t5,s11,0x24
    80000a36:	0df2                	slli	s11,s11,0x1c
    80000a38:	9dfa                	add	s11,s11,t5
    BCe = MLK_KECCAK_ROL(Egu, 20);
    Eka ^= Da;
    80000a3a:	011e4e33          	xor	t3,t3,a7
    BCe = MLK_KECCAK_ROL(Egu, 20);
    80000a3e:	02c2df13          	srli	t5,t0,0x2c
    80000a42:	02d2                	slli	t0,t0,0x14
    80000a44:	92fa                	add	t0,t0,t5
    BCi = MLK_KECCAK_ROL(Eka, 3);
    Eme ^= De;
    80000a46:	01d3c3b3          	xor	t2,t2,t4
    BCi = MLK_KECCAK_ROL(Eka, 3);
    80000a4a:	03de5f13          	srli	t5,t3,0x3d
    80000a4e:	0e0e                	slli	t3,t3,0x3
    80000a50:	9e7a                	add	t3,t3,t5
    BCo = MLK_KECCAK_ROL(Eme, 45);
    Esi ^= Di;
    80000a52:	8ebd                	xor	a3,a3,a5
    BCo = MLK_KECCAK_ROL(Eme, 45);
    80000a54:	0133df13          	srli	t5,t2,0x13
    80000a58:	13b6                	slli	t2,t2,0x2d
    80000a5a:	93fa                	add	t2,t2,t5
    BCu = MLK_KECCAK_ROL(Esi, 61);
    80000a5c:	0036df13          	srli	t5,a3,0x3
    80000a60:	16f6                	slli	a3,a3,0x3d
    80000a62:	96fa                	add	a3,a3,t5
    Abo = BCo ^ ((~BCu) & BCa);
    80000a64:	8da1                	xor	a1,a1,s0
    Abu = BCu ^ ((~BCa) & BCe);
    80000a66:	0129c433          	xor	s0,s3,s2
    Aga = BCa ^ ((~BCe) & BCi);
    Age = BCe ^ ((~BCi) & BCo);
    Agi = BCi ^ ((~BCo) & BCu);
    80000a6a:	fff3c913          	not	s2,t2
    Aga = BCa ^ ((~BCe) & BCi);
    80000a6e:	fff2cf13          	not	t5,t0
    Agi = BCi ^ ((~BCo) & BCu);
    80000a72:	00d97933          	and	s2,s2,a3
    Aga = BCa ^ ((~BCe) & BCi);
    80000a76:	01cf7f33          	and	t5,t5,t3
    Age = BCe ^ ((~BCi) & BCo);
    80000a7a:	fffe4993          	not	s3,t3
    Agi = BCi ^ ((~BCo) & BCu);
    80000a7e:	01c94933          	xor	s2,s2,t3
    Ago = BCo ^ ((~BCu) & BCa);
    80000a82:	fff6ce13          	not	t3,a3
    80000a86:	01be7e33          	and	t3,t3,s11
    Abu = BCu ^ ((~BCa) & BCe);
    80000a8a:	ec22                	sd	s0,24(sp)
    Aga = BCa ^ ((~BCe) & BCi);
    80000a8c:	01bf4433          	xor	s0,t5,s11
    80000a90:	f022                	sd	s0,32(sp)
    Ago = BCo ^ ((~BCu) & BCa);
    80000a92:	007e4433          	xor	s0,t3,t2
    80000a96:	f422                	sd	s0,40(sp)
    Agu = BCu ^ ((~BCa) & BCe);

    Ebe ^= De;
    80000a98:	6426                	ld	s0,72(sp)
    Age = BCe ^ ((~BCi) & BCo);
    80000a9a:	0079f9b3          	and	s3,s3,t2
    Agu = BCu ^ ((~BCa) & BCe);
    80000a9e:	fffdcd93          	not	s11,s11
    Ebe ^= De;
    80000aa2:	01d44e33          	xor	t3,s0,t4
    BCa = MLK_KECCAK_ROL(Ebe, 1);
    Egi ^= Di;
    80000aa6:	7406                	ld	s0,96(sp)
    BCa = MLK_KECCAK_ROL(Ebe, 1);
    80000aa8:	03fe5f13          	srli	t5,t3,0x3f
    80000aac:	0e06                	slli	t3,t3,0x1
    80000aae:	9e7a                	add	t3,t3,t5
    Egi ^= Di;
    80000ab0:	00f44f33          	xor	t5,s0,a5
    BCe = MLK_KECCAK_ROL(Egi, 6);
    Eko ^= Do;
    80000ab4:	0104c4b3          	xor	s1,s1,a6
    Agu = BCu ^ ((~BCa) & BCe);
    80000ab8:	005dfdb3          	and	s11,s11,t0
    Age = BCe ^ ((~BCi) & BCo);
    80000abc:	0059c9b3          	xor	s3,s3,t0
    BCe = MLK_KECCAK_ROL(Egi, 6);
    80000ac0:	03af5293          	srli	t0,t5,0x3a
    80000ac4:	0f1a                	slli	t5,t5,0x6
    80000ac6:	9f16                	add	t5,t5,t0
    BCi = MLK_KECCAK_ROL(Eko, 25);
    80000ac8:	0274d393          	srli	t2,s1,0x27
    Emu ^= Du;
    80000acc:	00664633          	xor	a2,a2,t1
    BCi = MLK_KECCAK_ROL(Eko, 25);
    80000ad0:	01949293          	slli	t0,s1,0x19
    80000ad4:	929e                	add	t0,t0,t2
    BCo = MLK_KECCAK_ROL(Emu, 8);
    Esa ^= Da;
    80000ad6:	011fcfb3          	xor	t6,t6,a7
    BCo = MLK_KECCAK_ROL(Emu, 8);
    80000ada:	03865393          	srli	t2,a2,0x38
    80000ade:	0622                	slli	a2,a2,0x8
    80000ae0:	961e                	add	a2,a2,t2
    BCu = MLK_KECCAK_ROL(Esa, 18);
    80000ae2:	02efd393          	srli	t2,t6,0x2e
    80000ae6:	0fca                	slli	t6,t6,0x12
    80000ae8:	9f9e                	add	t6,t6,t2
    Aka = BCa ^ ((~BCe) & BCi);
    Ake = BCe ^ ((~BCi) & BCo);
    80000aea:	fff2c393          	not	t2,t0
    80000aee:	00c3f3b3          	and	t2,t2,a2
    Aka = BCa ^ ((~BCe) & BCi);
    80000af2:	ffff4493          	not	s1,t5
    Ake = BCe ^ ((~BCi) & BCo);
    80000af6:	01e3c433          	xor	s0,t2,t5
    Aka = BCa ^ ((~BCe) & BCi);
    80000afa:	0054f4b3          	and	s1,s1,t0
    Aki = BCi ^ ((~BCo) & BCu);
    Ako = BCo ^ ((~BCu) & BCa);
    80000afe:	ffffc393          	not	t2,t6
    80000b02:	01c3f3b3          	and	t2,t2,t3
    Aka = BCa ^ ((~BCe) & BCi);
    80000b06:	01c4c4b3          	xor	s1,s1,t3
    Aku = BCu ^ ((~BCa) & BCe);
    80000b0a:	fffe4e13          	not	t3,t3
    80000b0e:	01ee7e33          	and	t3,t3,t5
    Ake = BCe ^ ((~BCi) & BCo);
    80000b12:	f822                	sd	s0,48(sp)
    Ako = BCo ^ ((~BCu) & BCa);
    80000b14:	00c3c3b3          	xor	t2,t2,a2
    Aki = BCi ^ ((~BCo) & BCu);
    80000b18:	fff64413          	not	s0,a2
    Aku = BCu ^ ((~BCa) & BCe);
    80000b1c:	01fe4633          	xor	a2,t3,t6
    80000b20:	fc32                	sd	a2,56(sp)

    Ebu ^= Du;
    80000b22:	6646                	ld	a2,80(sp)
    Aki = BCi ^ ((~BCo) & BCu);
    80000b24:	01f47433          	and	s0,s0,t6
    BCe = MLK_KECCAK_ROL(Ega, 36);
    Eke ^= De;
    BCi = MLK_KECCAK_ROL(Eke, 10);
    Emi ^= Di;
    BCo = MLK_KECCAK_ROL(Emi, 15);
    Eso ^= Do;
    80000b28:	01074733          	xor	a4,a4,a6
    Ebu ^= Du;
    80000b2c:	00664633          	xor	a2,a2,t1
    BCa = MLK_KECCAK_ROL(Ebu, 27);
    80000b30:	02565e13          	srli	t3,a2,0x25
    80000b34:	066e                	slli	a2,a2,0x1b
    80000b36:	9672                	add	a2,a2,t3
    Ega ^= Da;
    80000b38:	6e66                	ld	t3,88(sp)
    Aki = BCi ^ ((~BCo) & BCu);
    80000b3a:	00544433          	xor	s0,s0,t0
    Agu = BCu ^ ((~BCa) & BCe);
    80000b3e:	00ddc6b3          	xor	a3,s11,a3
    Ega ^= Da;
    80000b42:	011e4e33          	xor	t3,t3,a7
    BCe = MLK_KECCAK_ROL(Ega, 36);
    80000b46:	01ce5f13          	srli	t5,t3,0x1c
    80000b4a:	1e12                	slli	t3,t3,0x24
    80000b4c:	9e7a                	add	t3,t3,t5
    Eke ^= De;
    80000b4e:	7f46                	ld	t5,112(sp)
    80000b50:	01df4f33          	xor	t5,t5,t4
    BCi = MLK_KECCAK_ROL(Eke, 10);
    80000b54:	036f5f93          	srli	t6,t5,0x36
    80000b58:	0f2a                	slli	t5,t5,0xa
    80000b5a:	9f7e                	add	t5,t5,t6
    Emi ^= Di;
    80000b5c:	6faa                	ld	t6,136(sp)
    BCu = MLK_KECCAK_ROL(Eso, 56);
    Ama = BCa ^ ((~BCe) & BCi);
    Ame = BCe ^ ((~BCi) & BCo);
    80000b5e:	ffff4293          	not	t0,t5
    Emi ^= Di;
    80000b62:	00ffcab3          	xor	s5,t6,a5
    BCo = MLK_KECCAK_ROL(Emi, 15);
    80000b66:	031adf93          	srli	t6,s5,0x31
    80000b6a:	0abe                	slli	s5,s5,0xf
    80000b6c:	9afe                	add	s5,s5,t6
    BCu = MLK_KECCAK_ROL(Eso, 56);
    80000b6e:	00875f93          	srli	t6,a4,0x8
    80000b72:	1762                	slli	a4,a4,0x38
    80000b74:	977e                	add	a4,a4,t6
    Ama = BCa ^ ((~BCe) & BCi);
    80000b76:	fffe4f93          	not	t6,t3
    80000b7a:	01efffb3          	and	t6,t6,t5
    80000b7e:	00cfcfb3          	xor	t6,t6,a2
    80000b82:	e0fe                	sd	t6,64(sp)
    Ami = BCi ^ ((~BCo) & BCu);
    80000b84:	fffacf93          	not	t6,s5
    80000b88:	00efffb3          	and	t6,t6,a4
    80000b8c:	01efcfb3          	xor	t6,t6,t5
    Amo = BCo ^ ((~BCu) & BCa);
    80000b90:	fff74f13          	not	t5,a4
    80000b94:	00cf7f33          	and	t5,t5,a2
    Amu = BCu ^ ((~BCa) & BCe);
    80000b98:	fff64613          	not	a2,a2
    80000b9c:	01c67633          	and	a2,a2,t3

    Ebi ^= Di;
    80000ba0:	00fb47b3          	xor	a5,s6,a5
    Amu = BCu ^ ((~BCa) & BCe);
    80000ba4:	8f31                	xor	a4,a4,a2
    BCa = MLK_KECCAK_ROL(Ebi, 62);
    80000ba6:	0027d613          	srli	a2,a5,0x2
    80000baa:	17fa                	slli	a5,a5,0x3e
    80000bac:	97b2                	add	a5,a5,a2
    Ego ^= Do;
    80000bae:	7626                	ld	a2,104(sp)
    Ame = BCe ^ ((~BCi) & BCo);
    80000bb0:	0152f2b3          	and	t0,t0,s5
    80000bb4:	01c2c2b3          	xor	t0,t0,t3
    Ego ^= Do;
    80000bb8:	01064833          	xor	a6,a2,a6
    BCe = MLK_KECCAK_ROL(Ego, 55);
    80000bbc:	00985613          	srli	a2,a6,0x9
    80000bc0:	185e                	slli	a6,a6,0x37
    80000bc2:	9832                	add	a6,a6,a2
    Eku ^= Du;
    80000bc4:	7666                	ld	a2,120(sp)
    Amo = BCo ^ ((~BCu) & BCa);
    80000bc6:	015f4f33          	xor	t5,t5,s5
    Eku ^= Du;
    80000bca:	00664333          	xor	t1,a2,t1
    BCi = MLK_KECCAK_ROL(Eku, 39);
    80000bce:	01935613          	srli	a2,t1,0x19
    80000bd2:	131e                	slli	t1,t1,0x27
    80000bd4:	9332                	add	t1,t1,a2
    Ema ^= Da;
    80000bd6:	660a                	ld	a2,128(sp)
    BCo = MLK_KECCAK_ROL(Ema, 41);
    Ese ^= De;
    BCu = MLK_KECCAK_ROL(Ese, 2);
    Asa = BCa ^ ((~BCe) & BCi);
    Ase = BCe ^ ((~BCi) & BCo);
    80000bd8:	fff34d13          	not	s10,t1
    Ema ^= Da;
    80000bdc:	011648b3          	xor	a7,a2,a7
    BCo = MLK_KECCAK_ROL(Ema, 41);
    80000be0:	0178d613          	srli	a2,a7,0x17
    80000be4:	18a6                	slli	a7,a7,0x29
    80000be6:	98b2                	add	a7,a7,a2
    Ese ^= De;
    80000be8:	01dc4633          	xor	a2,s8,t4
    BCu = MLK_KECCAK_ROL(Ese, 2);
    80000bec:	03e65e13          	srli	t3,a2,0x3e
    80000bf0:	060a                	slli	a2,a2,0x2
    80000bf2:	9672                	add	a2,a2,t3
    Asi = BCi ^ ((~BCo) & BCu);
    80000bf4:	fff8ce13          	not	t3,a7
    Asa = BCa ^ ((~BCe) & BCi);
    80000bf8:	fff84e93          	not	t4,a6
    Asi = BCi ^ ((~BCo) & BCu);
    80000bfc:	00ce7e33          	and	t3,t3,a2
    Asa = BCa ^ ((~BCe) & BCi);
    80000c00:	006efeb3          	and	t4,t4,t1
    Asi = BCi ^ ((~BCo) & BCu);
    80000c04:	006e4e33          	xor	t3,t3,t1
    Aso = BCo ^ ((~BCu) & BCa);
    80000c08:	fff64313          	not	t1,a2
    80000c0c:	00f37333          	and	t1,t1,a5
    Asa = BCa ^ ((~BCe) & BCi);
    80000c10:	00feceb3          	xor	t4,t4,a5
    Asu = BCu ^ ((~BCa) & BCe);
    80000c14:	fff7c793          	not	a5,a5
    80000c18:	0107f7b3          	and	a5,a5,a6
    80000c1c:	8e3d                	xor	a2,a2,a5
  for (round = 0; round < MLK_KECCAK_NROUNDS; round += 2)
    80000c1e:	6782                	ld	a5,0(sp)
    Ase = BCe ^ ((~BCi) & BCo);
    80000c20:	011d7d33          	and	s10,s10,a7
    80000c24:	010d4d33          	xor	s10,s10,a6
  for (round = 0; round < MLK_KECCAK_NROUNDS; round += 2)
    80000c28:	07c1                	addi	a5,a5,16
    80000c2a:	e03e                	sd	a5,0(sp)
    80000c2c:	6802                	ld	a6,0(sp)
    80000c2e:	00002797          	auipc	a5,0x2
    80000c32:	7b278793          	addi	a5,a5,1970 # 800033e0 <mlk_zetas>
    Aso = BCo ^ ((~BCu) & BCa);
    80000c36:	01134333          	xor	t1,t1,a7
  for (round = 0; round < MLK_KECCAK_NROUNDS; round += 2)
    80000c3a:	9d0799e3          	bne	a5,a6,8000060c <mlk_keccakf1600_permute_c+0x7c>
  }

  /* copyToState(state, A) */
  state[0] = Aba;
  state[1] = Abe;
    80000c3e:	67a2                	ld	a5,8(sp)
  state[0] = Aba;
    80000c40:	01453023          	sd	s4,0(a0)
  state[2] = Abi;
  state[3] = Abo;
  state[4] = Abu;
  state[5] = Aga;
  state[6] = Age;
    80000c44:	03353823          	sd	s3,48(a0)
  state[1] = Abe;
    80000c48:	e51c                	sd	a5,8(a0)
  state[2] = Abi;
    80000c4a:	67c2                	ld	a5,16(sp)
  state[7] = Agi;
    80000c4c:	03253c23          	sd	s2,56(a0)
  state[8] = Ago;
  state[9] = Agu;
  state[10] = Aka;
    80000c50:	e924                	sd	s1,80(a0)
  state[2] = Abi;
    80000c52:	e91c                	sd	a5,16(a0)
  state[4] = Abu;
    80000c54:	67e2                	ld	a5,24(sp)
  state[11] = Ake;
  state[12] = Aki;
    80000c56:	f120                	sd	s0,96(a0)
  state[16] = Ame;
  state[17] = Ami;
  state[18] = Amo;
  state[19] = Amu;
  state[20] = Asa;
  state[21] = Ase;
    80000c58:	0ba53423          	sd	s10,168(a0)
  state[4] = Abu;
    80000c5c:	f11c                	sd	a5,32(a0)
  state[5] = Aga;
    80000c5e:	7782                	ld	a5,32(sp)
  state[3] = Abo;
    80000c60:	ed0c                	sd	a1,24(a0)
  state[9] = Agu;
    80000c62:	e534                	sd	a3,72(a0)
  state[5] = Aga;
    80000c64:	f51c                	sd	a5,40(a0)
  state[8] = Ago;
    80000c66:	77a2                	ld	a5,40(sp)
  state[13] = Ako;
    80000c68:	06753423          	sd	t2,104(a0)
  state[16] = Ame;
    80000c6c:	08553023          	sd	t0,128(a0)
  state[8] = Ago;
    80000c70:	e13c                	sd	a5,64(a0)
  state[11] = Ake;
    80000c72:	77c2                	ld	a5,48(sp)
  state[17] = Ami;
    80000c74:	09f53423          	sd	t6,136(a0)
  state[18] = Amo;
    80000c78:	09e53823          	sd	t5,144(a0)
  state[11] = Ake;
    80000c7c:	ed3c                	sd	a5,88(a0)
  state[14] = Aku;
    80000c7e:	77e2                	ld	a5,56(sp)
  state[19] = Amu;
    80000c80:	ed58                	sd	a4,152(a0)
  state[20] = Asa;
    80000c82:	0bd53023          	sd	t4,160(a0)
  state[14] = Aku;
    80000c86:	f93c                	sd	a5,112(a0)
  state[15] = Ama;
    80000c88:	6786                	ld	a5,64(sp)
  state[22] = Asi;
    80000c8a:	0bc53823          	sd	t3,176(a0)
  state[23] = Aso;
    80000c8e:	0a653c23          	sd	t1,184(a0)
  state[15] = Ama;
    80000c92:	fd3c                	sd	a5,120(a0)
  state[24] = Asu;
    80000c94:	e170                	sd	a2,192(a0)
}
    80000c96:	742e                	ld	s0,232(sp)
    80000c98:	748e                	ld	s1,224(sp)
    80000c9a:	696e                	ld	s2,216(sp)
    80000c9c:	69ce                	ld	s3,208(sp)
    80000c9e:	6a2e                	ld	s4,200(sp)
    80000ca0:	6a8e                	ld	s5,192(sp)
    80000ca2:	7b6a                	ld	s6,184(sp)
    80000ca4:	7bca                	ld	s7,176(sp)
    80000ca6:	7c2a                	ld	s8,168(sp)
    80000ca8:	7c8a                	ld	s9,160(sp)
    80000caa:	6d6a                	ld	s10,152(sp)
    80000cac:	6dca                	ld	s11,144(sp)
    80000cae:	616d                	addi	sp,sp,240
    80000cb0:	8082                	ret

0000000080000cb2 <mlk_rej_uniform_c.constprop.0>:
  while (ctr < target && pos + 3 <= buflen)
    80000cb2:	430d                	li	t1,3
    if (val0 < MLKEM_Q)
    80000cb4:	6805                	lui	a6,0x1
  while (ctr < target && pos + 3 <= buflen)
    80000cb6:	0ff00f13          	li	t5,255
    80000cba:	40c3033b          	subw	t1,t1,a2
    if (val0 < MLKEM_Q)
    80000cbe:	d0080813          	addi	a6,a6,-768 # d00 <_heap_size-0x3300>
    if (ctr < target && val1 < MLKEM_Q)
    80000cc2:	10000e13          	li	t3,256
  while (ctr < target && pos + 3 <= buflen)
    80000cc6:	04bf7363          	bgeu	t5,a1,80000d0c <mlk_rej_uniform_c.constprop.0+0x5a>
}
    80000cca:	852e                	mv	a0,a1
    80000ccc:	8082                	ret
    val0 = (int16_t)(((buf[pos + 0] >> 0) | ((uint16_t)buf[pos + 1] << 8)) &
    80000cce:	00164883          	lbu	a7,1(a2)
    80000cd2:	00064703          	lbu	a4,0(a2)
    80000cd6:	0088979b          	slliw	a5,a7,0x8
    80000cda:	8fd9                	or	a5,a5,a4
    80000cdc:	17d2                	slli	a5,a5,0x34
    80000cde:	93d1                	srli	a5,a5,0x34
    val1 = (int16_t)(((buf[pos + 1] >> 4) | (buf[pos + 2] << 4)) & 0xFFF);
    80000ce0:	00264703          	lbu	a4,2(a2)
    if (val0 < MLKEM_Q)
    80000ce4:	00f84b63          	blt	a6,a5,80000cfa <mlk_rej_uniform_c.constprop.0+0x48>
      r[ctr++] = val0;
    80000ce8:	00158e9b          	addiw	t4,a1,1
    80000cec:	0586                	slli	a1,a1,0x1
    80000cee:	95aa                	add	a1,a1,a0
    80000cf0:	00f59023          	sh	a5,0(a1)
    if (ctr < target && val1 < MLKEM_Q)
    80000cf4:	03ce8963          	beq	t4,t3,80000d26 <mlk_rej_uniform_c.constprop.0+0x74>
    80000cf8:	85f6                	mv	a1,t4
    val1 = (int16_t)(((buf[pos + 1] >> 4) | (buf[pos + 2] << 4)) & 0xFFF);
    80000cfa:	0048d89b          	srliw	a7,a7,0x4
    80000cfe:	0047179b          	slliw	a5,a4,0x4
    80000d02:	0117e7b3          	or	a5,a5,a7
    if (ctr < target && val1 < MLKEM_Q)
    80000d06:	00f85863          	bge	a6,a5,80000d16 <mlk_rej_uniform_c.constprop.0+0x64>
    80000d0a:	060d                	addi	a2,a2,3
  while (ctr < target && pos + 3 <= buflen)
    80000d0c:	00c307bb          	addw	a5,t1,a2
    80000d10:	faf6ffe3          	bgeu	a3,a5,80000cce <mlk_rej_uniform_c.constprop.0+0x1c>
    80000d14:	bf5d                	j	80000cca <mlk_rej_uniform_c.constprop.0+0x18>
      r[ctr++] = val1;
    80000d16:	00159713          	slli	a4,a1,0x1
    80000d1a:	972a                	add	a4,a4,a0
    80000d1c:	00f71023          	sh	a5,0(a4)
    80000d20:	060d                	addi	a2,a2,3
    80000d22:	2585                	addiw	a1,a1,1
    80000d24:	b74d                	j	80000cc6 <mlk_rej_uniform_c.constprop.0+0x14>
    if (ctr < target && val1 < MLKEM_Q)
    80000d26:	85f2                	mv	a1,t3
    80000d28:	b74d                	j	80000cca <mlk_rej_uniform_c.constprop.0+0x18>

0000000080000d2a <mlk_poly_reduce_c>:
  const int32_t t = (magic * a + ((int32_t)1 << 25)) >> 26;
    80000d2a:	6815                	lui	a6,0x5
  int16_t res = (int16_t)(a - t * MLKEM_Q);
    80000d2c:	6585                	lui	a1,0x1
    80000d2e:	20050313          	addi	t1,a0,512
  const int32_t t = (magic * a + ((int32_t)1 << 25)) >> 26;
    80000d32:	ebf8081b          	addiw	a6,a6,-321 # 4ebf <_heap_size+0xebf>
    80000d36:	02000e37          	lui	t3,0x2000
  int16_t res = (int16_t)(a - t * MLKEM_Q);
    80000d3a:	d015859b          	addiw	a1,a1,-767 # d01 <_heap_size-0x32ff>
 *
 * Its validity relies on the assumption that the global opt-blocker
 * constant mlk_ct_opt_blocker_u64 is not modified.
 */
static MLK_INLINE uint64_t mlk_ct_get_optblocker_u64(void)
__contract__(ensures(return_value == 0)) { return mlk_ct_opt_blocker_u64; }
    80000d3e:	81018893          	addi	a7,gp,-2032 # 800034f0 <mlkem_ct_opt_blocker_u64>
    int16_t t = mlk_barrett_reduce(r->coeffs[i]);
    80000d42:	00051703          	lh	a4,0(a0)
  for (i = 0; i < MLKEM_N; i++)
    80000d46:	0509                	addi	a0,a0,2
  const int32_t t = (magic * a + ((int32_t)1 << 25)) >> 26;
    80000d48:	030707bb          	mulw	a5,a4,a6
    80000d4c:	00fe07bb          	addw	a5,t3,a5
    80000d50:	41a7d79b          	sraiw	a5,a5,0x1a
  int16_t res = (int16_t)(a - t * MLKEM_Q);
    80000d54:	02f587bb          	mulw	a5,a1,a5
    80000d58:	9f1d                	subw	a4,a4,a5
    80000d5a:	0008b783          	ld	a5,0(a7)
    80000d5e:	0107169b          	slliw	a3,a4,0x10
    80000d62:	4106d69b          	sraiw	a3,a3,0x10
    80000d66:	0008b603          	ld	a2,0(a7)
 * @return Mask value (0 or 0xFFFF).
 */
static MLK_INLINE uint16_t mlk_ct_cmask_nonzero_u16(uint16_t x)
__contract__(ensures(return_value == ((x == 0) ? 0 : 0xFFFF)))
{
  int32_t tmp = mlk_value_barrier_i32(-((int32_t)x));
    80000d6a:	8fb5                	xor	a5,a5,a3
    80000d6c:	0107d79b          	srliw	a5,a5,0x10
    80000d70:	40f007bb          	negw	a5,a5
__contract__(ensures(return_value == b)) { return (b ^ mlk_ct_get_optblocker_i32()); }
    80000d74:	8fb1                	xor	a5,a5,a2
  c = mlk_ct_sel_int16((int16_t)(c + MLKEM_Q), c, mlk_ct_cmask_neg_i16(c));
    80000d76:	5027061b          	addiw	a2,a4,1282
    80000d7a:	7ff6061b          	addiw	a2,a2,2047
   * PORTABILITY: Right-shift on a signed integer is
   * implementation-defined for negative left argument.
   * Here, we assume it's sign-preserving "arithmetic" shift right.
   * See (C99 6.5.7 (5))
   */
  tmp >>= 16;
    80000d7e:	4107d79b          	sraiw	a5,a5,0x10
  return (int16_t)x;
    80000d82:	8f31                	xor	a4,a4,a2
    80000d84:	8ff9                	and	a5,a5,a4
    80000d86:	8ebd                	xor	a3,a3,a5
    r->coeffs[i] = mlk_scalar_signed_to_unsigned_q(t);
    80000d88:	fed51f23          	sh	a3,-2(a0)
  for (i = 0; i < MLKEM_N; i++)
    80000d8c:	faa31be3          	bne	t1,a0,80000d42 <mlk_poly_reduce_c+0x18>
}
    80000d90:	8082                	ret

0000000080000d92 <mlkem_polyvec_reduce>:
 *              here to go from signed to unsigned representatives.
 *              This conditional addition is then dropped from all
 *              polynomial compression functions instead (see `compress.c`). */
MLK_INTERNAL_API
void mlk_polyvec_reduce(mlk_polyvec *r)
{
    80000d92:	1101                	addi	sp,sp,-32
    80000d94:	ec06                	sd	ra,24(sp)
    80000d96:	e42a                	sd	a0,8(sp)
  mlk_poly_reduce_c(r);
    80000d98:	f93ff0ef          	jal	80000d2a <mlk_poly_reduce_c>
    80000d9c:	6522                	ld	a0,8(sp)
  {
    mlk_poly_reduce(&r->vec[i]);
  }

  mlk_assert_bound_2d(r->vec, MLKEM_K, MLKEM_N, 0, MLKEM_Q);
}
    80000d9e:	60e2                	ld	ra,24(sp)
    80000da0:	20050513          	addi	a0,a0,512
    80000da4:	6105                	addi	sp,sp,32
    80000da6:	b751                	j	80000d2a <mlk_poly_reduce_c>

0000000080000da8 <mlkem_polyvec_ntt>:
{
    80000da8:	1101                	addi	sp,sp,-32
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000daa:	737d                	lui	t1,0xfffff
  r = a - ((int32_t)t * MLKEM_Q);
    80000dac:	7e7d                	lui	t3,0xfffff
    80000dae:	ec22                	sd	s0,24(sp)
    80000db0:	e826                	sd	s1,16(sp)
    80000db2:	e44a                	sd	s2,8(sp)
    80000db4:	e04e                	sd	s3,0(sp)
    80000db6:	40050f93          	addi	t6,a0,1024
  assigns(memory_slice(r, sizeof(int16_t) * MLKEM_N))
  ensures(array_abs_bound(r, 0, MLKEM_N, (layer + 1) * MLKEM_Q)))
{
  unsigned start, k, len;
  /* Twiddle factors for layer n are at indices 2^(n-1)..2^n-1. */
  k = 1u << (layer - 1);
    80000dba:	4285                	li	t0,1
  len = (unsigned)MLKEM_N >> layer;
    80000dbc:	10000393          	li	t2,256
    invariant(k <= MLKEM_N / 2 && 2 * len * k == start + MLKEM_N)
    invariant(array_abs_bound(r, 0, start, layer * MLKEM_Q + MLKEM_Q))
    invariant(array_abs_bound(r, start, MLKEM_N, layer * MLKEM_Q))
    decreases(MLKEM_N - start))
  {
    int16_t zeta = mlk_zetas[k++];
    80000dc0:	00002417          	auipc	s0,0x2
    80000dc4:	56040413          	addi	s0,s0,1376 # 80003320 <mlk_KeccakF_RoundConstants>
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000dc8:	3013031b          	addiw	t1,t1,769 # fffffffffffff301 <_stack_start+0xffffffff7ffe7141>
  r = a - ((int32_t)t * MLKEM_Q);
    80000dcc:	2ffe0e1b          	addiw	t3,t3,767 # fffffffffffff2ff <_stack_start+0xffffffff7ffe713f>
  for (start = 0; start < MLKEM_N; start += 2 * len)
    80000dd0:	0ff00493          	li	s1,255

  mlk_assert_abs_bound(p, MLKEM_N, MLKEM_Q);

  r = p->coeffs;

  for (layer = 1; layer <= 7; layer++)
    80000dd4:	4921                	li	s2,8
    80000dd6:	4585                	li	a1,1
  k = 1u << (layer - 1);
    80000dd8:	fff5881b          	addiw	a6,a1,-1
    80000ddc:	0102983b          	sllw	a6,t0,a6
  len = (unsigned)MLKEM_N >> layer;
    80000de0:	00b3df3b          	srlw	t5,t2,a1
  for (start = 0; start < MLKEM_N; start += 2 * len)
    80000de4:	4701                	li	a4,0
    int16_t zeta = mlk_zetas[k++];
    80000de6:	02081693          	slli	a3,a6,0x20
    80000dea:	01f6d793          	srli	a5,a3,0x1f
    80000dee:	97a2                	add	a5,a5,s0
    80000df0:	00ef0ebb          	addw	t4,t5,a4
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000df4:	0c079983          	lh	s3,192(a5)
    80000df8:	001e9613          	slli	a2,t4,0x1
    80000dfc:	00171693          	slli	a3,a4,0x1
    int16_t zeta = mlk_zetas[k++];
    80000e00:	2805                	addiw	a6,a6,1
    80000e02:	962a                	add	a2,a2,a0
    80000e04:	96aa                	add	a3,a3,a0
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000e06:	00061883          	lh	a7,0(a2)
  for (j = start; j < start + len; j++)
    80000e0a:	2705                	addiw	a4,a4,1
    80000e0c:	0609                	addi	a2,a2,2
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000e0e:	033888bb          	mulw	a7,a7,s3
  for (j = start; j < start + len; j++)
    80000e12:	0689                	addi	a3,a3,2
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000e14:	031307bb          	mulw	a5,t1,a7
  r = a - ((int32_t)t * MLKEM_Q);
    80000e18:	0107979b          	slliw	a5,a5,0x10
    80000e1c:	4107d79b          	sraiw	a5,a5,0x10
    80000e20:	03c787bb          	mulw	a5,a5,t3
    80000e24:	011787bb          	addw	a5,a5,a7
    r[j + len] = (int16_t)(r[j] - t);
    80000e28:	ffe6d883          	lhu	a7,-2(a3)
    80000e2c:	87c1                	srai	a5,a5,0x10
    80000e2e:	40f888bb          	subw	a7,a7,a5
    80000e32:	ff161f23          	sh	a7,-2(a2)
    r[j] = (int16_t)(r[j] + t);
    80000e36:	ffe6d883          	lhu	a7,-2(a3)
    80000e3a:	00f887bb          	addw	a5,a7,a5
    80000e3e:	fef69f23          	sh	a5,-2(a3)
  for (j = start; j < start + len; j++)
    80000e42:	fdd762e3          	bltu	a4,t4,80000e06 <mlkem_polyvec_ntt+0x5e>
  for (start = 0; start < MLKEM_N; start += 2 * len)
    80000e46:	01df073b          	addw	a4,t5,t4
    80000e4a:	f8e4fee3          	bgeu	s1,a4,80000de6 <mlkem_polyvec_ntt+0x3e>
  for (layer = 1; layer <= 7; layer++)
    80000e4e:	2585                	addiw	a1,a1,1
    80000e50:	f92594e3          	bne	a1,s2,80000dd8 <mlkem_polyvec_ntt+0x30>
  for (i = 0; i < MLKEM_K; i++)
    80000e54:	20050513          	addi	a0,a0,512
    80000e58:	f6af9fe3          	bne	t6,a0,80000dd6 <mlkem_polyvec_ntt+0x2e>
}
    80000e5c:	6462                	ld	s0,24(sp)
    80000e5e:	64c2                	ld	s1,16(sp)
    80000e60:	6922                	ld	s2,8(sp)
    80000e62:	6982                	ld	s3,0(sp)
    80000e64:	6105                	addi	sp,sp,32
    80000e66:	8082                	ret

0000000080000e68 <mlk_poly_invntt_tomont_c>:
__contract__(
  requires(memory_no_alias(p, sizeof(mlk_poly)))
  assigns(memory_slice(p, sizeof(mlk_poly)))
  ensures(array_abs_bound(p->coeffs, 0, MLKEM_N, MLK_INVNTT_BOUND))
)
{
    80000e68:	7179                	addi	sp,sp,-48
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000e6a:	75fd                	lui	a1,0xfffff
  r = a - ((int32_t)t * MLKEM_Q);
    80000e6c:	767d                	lui	a2,0xfffff
    80000e6e:	f422                	sd	s0,40(sp)
    80000e70:	f026                	sd	s1,32(sp)
    80000e72:	ec4a                	sd	s2,24(sp)
    80000e74:	e84e                	sd	s3,16(sp)
    80000e76:	e452                	sd	s4,8(sp)
    80000e78:	e056                	sd	s5,0(sp)
    80000e7a:	20050813          	addi	a6,a0,512
    80000e7e:	872a                	mv	a4,a0
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000e80:	5a100893          	li	a7,1441
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000e84:	3015859b          	addiw	a1,a1,769 # fffffffffffff301 <_stack_start+0xffffffff7ffe7141>
  r = a - ((int32_t)t * MLKEM_Q);
    80000e88:	2ff6061b          	addiw	a2,a2,767 # fffffffffffff2ff <_stack_start+0xffffffff7ffe713f>
    80000e8c:	00071683          	lh	a3,0(a4)
  /*
   * Scale input polynomial to account for Montgomery factor
   * and NTT twist. This also brings coefficients down to
   * absolute value < MLKEM_Q.
   */
  for (j = 0; j < MLKEM_N; j++)
    80000e90:	0709                	addi	a4,a4,2
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000e92:	031686bb          	mulw	a3,a3,a7
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000e96:	02d587bb          	mulw	a5,a1,a3
  r = a - ((int32_t)t * MLKEM_Q);
    80000e9a:	0107979b          	slliw	a5,a5,0x10
    80000e9e:	4107d79b          	sraiw	a5,a5,0x10
    80000ea2:	02c787bb          	mulw	a5,a5,a2
    80000ea6:	9fb5                	addw	a5,a5,a3
  r = r >> 16;
    80000ea8:	4107d79b          	sraiw	a5,a5,0x10
  return (int16_t)r;
    80000eac:	fef71f23          	sh	a5,-2(a4)
  for (j = 0; j < MLKEM_N; j++)
    80000eb0:	fce81ee3          	bne	a6,a4,80000e8c <mlk_poly_invntt_tomont_c+0x24>
  const int32_t t = (magic * a + ((int32_t)1 << 25)) >> 26;
    80000eb4:	6815                	lui	a6,0x5
  int16_t res = (int16_t)(a - t * MLKEM_Q);
    80000eb6:	6885                	lui	a7,0x1
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000eb8:	737d                	lui	t1,0xfffff
  r = a - ((int32_t)t * MLKEM_Q);
    80000eba:	7e7d                	lui	t3,0xfffff
  {
    r[j] = mlk_fqmul(r[j], f);
  }

  /* Run the invNTT layers */
  for (layer = 7; layer > 0; layer--)
    80000ebc:	461d                	li	a2,7
  len = (unsigned)MLKEM_N >> layer;
    80000ebe:	10000f13          	li	t5,256
  k = (1u << layer) - 1;
    80000ec2:	4f85                	li	t6,1
    int16_t zeta = mlk_zetas[k--];
    80000ec4:	00002297          	auipc	t0,0x2
    80000ec8:	45c28293          	addi	t0,t0,1116 # 80003320 <mlk_KeccakF_RoundConstants>
  const int32_t t = (magic * a + ((int32_t)1 << 25)) >> 26;
    80000ecc:	ebf8081b          	addiw	a6,a6,-321 # 4ebf <_heap_size+0xebf>
    80000ed0:	020003b7          	lui	t2,0x2000
  int16_t res = (int16_t)(a - t * MLKEM_Q);
    80000ed4:	d018889b          	addiw	a7,a7,-767 # d01 <_heap_size-0x32ff>
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000ed8:	3013031b          	addiw	t1,t1,769 # fffffffffffff301 <_stack_start+0xffffffff7ffe7141>
  r = a - ((int32_t)t * MLKEM_Q);
    80000edc:	2ffe0e1b          	addiw	t3,t3,767 # fffffffffffff2ff <_stack_start+0xffffffff7ffe713f>
  for (start = 0; start < MLKEM_N; start += 2 * len)
    80000ee0:	0ff00413          	li	s0,255
  k = (1u << layer) - 1;
    80000ee4:	00cf95bb          	sllw	a1,t6,a2
  len = (unsigned)MLKEM_N >> layer;
    80000ee8:	00cf5ebb          	srlw	t4,t5,a2
  k = (1u << layer) - 1;
    80000eec:	35fd                	addiw	a1,a1,-1
  for (start = 0; start < MLKEM_N; start += 2 * len)
    80000eee:	4781                	li	a5,0
    int16_t zeta = mlk_zetas[k--];
    80000ef0:	02059693          	slli	a3,a1,0x20
    80000ef4:	01f6d713          	srli	a4,a3,0x1f
    80000ef8:	9716                	add	a4,a4,t0
    80000efa:	00fe893b          	addw	s2,t4,a5
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000efe:	0c071483          	lh	s1,192(a4)
    80000f02:	00191693          	slli	a3,s2,0x1
    int16_t zeta = mlk_zetas[k--];
    80000f06:	35fd                	addiw	a1,a1,-1
    80000f08:	96aa                	add	a3,a3,a0
      int16_t t = r[j];
    80000f0a:	00179a93          	slli	s5,a5,0x1
    80000f0e:	9aaa                	add	s5,s5,a0
      r[j] = mlk_barrett_reduce((int16_t)(t + r[j + len]));
    80000f10:	000ada03          	lhu	s4,0(s5)
    80000f14:	0006d983          	lhu	s3,0(a3)
    for (j = start; j < start + len; j++)
    80000f18:	0785                	addi	a5,a5,1
    80000f1a:	0689                	addi	a3,a3,2
      r[j] = mlk_barrett_reduce((int16_t)(t + r[j + len]));
    80000f1c:	99d2                	add	s3,s3,s4
  const int32_t t = (magic * a + ((int32_t)1 << 25)) >> 26;
    80000f1e:	0109971b          	slliw	a4,s3,0x10
    80000f22:	4107571b          	sraiw	a4,a4,0x10
    80000f26:	0307073b          	mulw	a4,a4,a6
    80000f2a:	00e3873b          	addw	a4,t2,a4
    80000f2e:	41a7571b          	sraiw	a4,a4,0x1a
  int16_t res = (int16_t)(a - t * MLKEM_Q);
    80000f32:	02e8873b          	mulw	a4,a7,a4
    80000f36:	40e989bb          	subw	s3,s3,a4
      r[j] = mlk_barrett_reduce((int16_t)(t + r[j + len]));
    80000f3a:	013a9023          	sh	s3,0(s5)
      r[j + len] = (int16_t)(r[j + len] - t);
    80000f3e:	ffe6d983          	lhu	s3,-2(a3)
    80000f42:	414989bb          	subw	s3,s3,s4
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000f46:	0109999b          	slliw	s3,s3,0x10
    80000f4a:	4109d99b          	sraiw	s3,s3,0x10
    80000f4e:	029989bb          	mulw	s3,s3,s1
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000f52:	0333073b          	mulw	a4,t1,s3
  r = a - ((int32_t)t * MLKEM_Q);
    80000f56:	0107171b          	slliw	a4,a4,0x10
    80000f5a:	4107571b          	sraiw	a4,a4,0x10
    80000f5e:	03c7073b          	mulw	a4,a4,t3
    80000f62:	0137073b          	addw	a4,a4,s3
  r = r >> 16;
    80000f66:	4107571b          	sraiw	a4,a4,0x10
  return (int16_t)r;
    80000f6a:	fee69f23          	sh	a4,-2(a3)
    for (j = start; j < start + len; j++)
    80000f6e:	0007871b          	sext.w	a4,a5
    80000f72:	f9276ce3          	bltu	a4,s2,80000f0a <mlk_poly_invntt_tomont_c+0xa2>
  for (start = 0; start < MLKEM_N; start += 2 * len)
    80000f76:	012e87bb          	addw	a5,t4,s2
    80000f7a:	f6f47be3          	bgeu	s0,a5,80000ef0 <mlk_poly_invntt_tomont_c+0x88>
  for (layer = 7; layer > 0; layer--)
    80000f7e:	367d                	addiw	a2,a2,-1
    80000f80:	f235                	bnez	a2,80000ee4 <mlk_poly_invntt_tomont_c+0x7c>
  {
    mlk_invntt_layer(r, layer);
  }

  mlk_assert_abs_bound(p, MLKEM_N, MLK_INVNTT_BOUND);
}
    80000f82:	7422                	ld	s0,40(sp)
    80000f84:	7482                	ld	s1,32(sp)
    80000f86:	6962                	ld	s2,24(sp)
    80000f88:	69c2                	ld	s3,16(sp)
    80000f8a:	6a22                	ld	s4,8(sp)
    80000f8c:	6a82                	ld	s5,0(sp)
    80000f8e:	6145                	addi	sp,sp,48
    80000f90:	8082                	ret

0000000080000f92 <mlkem_polyvec_mulcache_compute>:
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000f92:	78fd                	lui	a7,0xfffff
  r = a - ((int32_t)t * MLKEM_Q);
    80000f94:	737d                	lui	t1,0xfffff
    80000f96:	40058e93          	addi	t4,a1,1024
    80000f9a:	00002f17          	auipc	t5,0x2
    80000f9e:	4c6f0f13          	addi	t5,t5,1222 # 80003460 <mlk_zetas+0x80>
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000fa2:	3018889b          	addiw	a7,a7,769 # fffffffffffff301 <_stack_start+0xffffffff7ffe7141>
  r = a - ((int32_t)t * MLKEM_Q);
    80000fa6:	2ff3031b          	addiw	t1,t1,767 # fffffffffffff2ff <_stack_start+0xffffffff7ffe713f>
  for (i = 0; i < MLKEM_N / 4; i++)
    80000faa:	00002817          	auipc	a6,0x2
    80000fae:	43680813          	addi	a6,a6,1078 # 800033e0 <mlk_zetas>
{
    80000fb2:	862a                	mv	a2,a0
    80000fb4:	86ae                	mv	a3,a1
    x->coeffs[2 * i + 0] = mlk_fqmul(a->coeffs[4 * i + 1], mlk_zetas[64 + i]);
    80000fb6:	08081703          	lh	a4,128(a6)
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000fba:	00269e03          	lh	t3,2(a3)
  for (i = 0; i < MLKEM_N / 4; i++)
    80000fbe:	0809                	addi	a6,a6,2
    80000fc0:	06a1                	addi	a3,a3,8
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000fc2:	02ee0e3b          	mulw	t3,t3,a4
        mlk_fqmul(a->coeffs[4 * i + 3], (int16_t)(-mlk_zetas[64 + i]));
    80000fc6:	40e0073b          	negw	a4,a4
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000fca:	0107171b          	slliw	a4,a4,0x10
    80000fce:	4107571b          	sraiw	a4,a4,0x10
  for (i = 0; i < MLKEM_N / 4; i++)
    80000fd2:	0611                	addi	a2,a2,4
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000fd4:	03c887bb          	mulw	a5,a7,t3
  r = a - ((int32_t)t * MLKEM_Q);
    80000fd8:	0107979b          	slliw	a5,a5,0x10
    80000fdc:	4107d79b          	sraiw	a5,a5,0x10
    80000fe0:	026787bb          	mulw	a5,a5,t1
    80000fe4:	01c787bb          	addw	a5,a5,t3
  r = r >> 16;
    80000fe8:	4107d79b          	sraiw	a5,a5,0x10
  return (int16_t)r;
    80000fec:	fef61e23          	sh	a5,-4(a2)
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80000ff0:	ffe69783          	lh	a5,-2(a3)
    80000ff4:	02e7873b          	mulw	a4,a5,a4
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80000ff8:	02e887bb          	mulw	a5,a7,a4
  r = a - ((int32_t)t * MLKEM_Q);
    80000ffc:	0107979b          	slliw	a5,a5,0x10
    80001000:	4107d79b          	sraiw	a5,a5,0x10
    80001004:	026787bb          	mulw	a5,a5,t1
    80001008:	9fb9                	addw	a5,a5,a4
  r = r >> 16;
    8000100a:	4107d79b          	sraiw	a5,a5,0x10
  return (int16_t)r;
    8000100e:	fef61f23          	sh	a5,-2(a2)
  for (i = 0; i < MLKEM_N / 4; i++)
    80001012:	fb0f12e3          	bne	t5,a6,80000fb6 <mlkem_polyvec_mulcache_compute+0x24>
  for (i = 0; i < MLKEM_K; i++)
    80001016:	20058593          	addi	a1,a1,512
    8000101a:	10050513          	addi	a0,a0,256
    8000101e:	f8be96e3          	bne	t4,a1,80000faa <mlkem_polyvec_mulcache_compute+0x18>
}
    80001022:	8082                	ret

0000000080001024 <mlk_ct_memcmp>:
  requires(len <= UINT16_MAX)
  requires(memory_no_alias(a, len))
  requires(memory_no_alias(b, len))
  ensures((return_value == 0) || (return_value == 0xFF))
  ensures((return_value == 0) == forall(i, 0, len, (a[i] == b[i]))))
{
    80001024:	4701                	li	a4,0
  uint8_t r = 0, s = 0;
    80001026:	4781                	li	a5,0
  __loop__(
    invariant(i <= len)
    invariant((r == 0) == (forall(k, 0, i, (a[k] == b[k]))))
    decreases(len - i))
  {
    r |= a[i] ^ b[i];
    80001028:	00e506b3          	add	a3,a0,a4
    8000102c:	00e58833          	add	a6,a1,a4
    80001030:	0006c683          	lbu	a3,0(a3)
    80001034:	00084803          	lbu	a6,0(a6)
  for (i = 0; i < len; i++)
    80001038:	0705                	addi	a4,a4,1
    r |= a[i] ^ b[i];
    8000103a:	0106c6b3          	xor	a3,a3,a6
    8000103e:	8fd5                	or	a5,a5,a3
  for (i = 0; i < len; i++)
    80001040:	fee614e3          	bne	a2,a4,80001028 <mlk_ct_memcmp+0x4>
__contract__(ensures(return_value == 0)) { return mlk_ct_opt_blocker_u64; }
    80001044:	81018713          	addi	a4,gp,-2032 # 800034f0 <mlkem_ct_opt_blocker_u64>
    80001048:	6314                	ld	a3,0(a4)
  int32_t tmp = mlk_value_barrier_i32(-((int32_t)x));
    8000104a:	40f0053b          	negw	a0,a5
__contract__(ensures(return_value == 0)) { return mlk_ct_opt_blocker_u64; }
    8000104e:	6318                	ld	a4,0(a4)
__contract__(ensures(return_value == b)) { return (b ^ mlk_ct_get_optblocker_i32()); }
    80001050:	8d35                	xor	a0,a0,a3
  tmp >>= 16;
    80001052:	4105551b          	sraiw	a0,a0,0x10
   *   safeguard
   *   towards leaking information about a and b.
   * - XOR twice with s, separated by a value barrier, to prevent the compile
   *   from dropping the s computation in the loop.
   */
  return (mlk_value_barrier_u8(mlk_ct_cmask_nonzero_u8(r) ^ s) ^ s);
    80001056:	8d39                	xor	a0,a0,a4
}
    80001058:	0ff57513          	zext.b	a0,a0
    8000105c:	8082                	ret

000000008000105e <mlkem_check_pk>:
/* Reference: Not implemented in the reference implementation @[REF]. */
MLK_EXTERNAL_API
MLK_MUST_CHECK_RETURN_VALUE
int mlk_kem_check_pk(const uint8_t pk[MLKEM_INDCCA_PUBLICKEYBYTES],
                     MLK_CONFIG_CONTEXT_PARAMETER_TYPE context)
{
    8000105e:	8d010113          	addi	sp,sp,-1840
    80001062:	72813023          	sd	s0,1824(sp)
    80001066:	01f10413          	addi	s0,sp,31
    8000106a:	9801                	andi	s0,s0,-32
    8000106c:	71213823          	sd	s2,1808(sp)
  {
    ret = MLK_ERR_OUT_OF_MEMORY;
    goto cleanup;
  }

  mlk_polyvec_frombytes(p, pk);
    80001070:	85aa                	mv	a1,a0
{
    80001072:	892a                	mv	s2,a0
  mlk_polyvec_frombytes(p, pk);
    80001074:	8522                	mv	a0,s0
{
    80001076:	72113423          	sd	ra,1832(sp)
    8000107a:	70913c23          	sd	s1,1816(sp)
  mlk_polyvec_frombytes(p, pk);
    8000107e:	b54ff0ef          	jal	800003d2 <mlkem_polyvec_frombytes>
  mlk_polyvec_reduce(p);
    80001082:	8522                	mv	a0,s0
    80001084:	d0fff0ef          	jal	80000d92 <mlkem_polyvec_reduce>
  mlk_polyvec_tobytes(p_reencoded, p);
    80001088:	85a2                	mv	a1,s0
    8000108a:	40040513          	addi	a0,s0,1024
    8000108e:	b00ff0ef          	jal	8000038e <mlkem_polyvec_tobytes>

  /* We use a constant-time memcmp here to avoid having to
   * declassify the PK before the PCT has succeeded. */
  ret = mlk_ct_memcmp(pk, p_reencoded, MLKEM_POLYVECBYTES) ? MLK_ERR_FAIL : 0;
    80001092:	30000613          	li	a2,768
    80001096:	40040593          	addi	a1,s0,1024
    8000109a:	854a                	mv	a0,s2
    8000109c:	f89ff0ef          	jal	80001024 <mlk_ct_memcmp>
    800010a0:	892a                	mv	s2,a0

cleanup:
  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  MLK_FREE(p_reencoded, uint8_t, MLKEM_POLYVECBYTES, context);
    800010a2:	30000593          	li	a1,768
    800010a6:	40040513          	addi	a0,s0,1024
    800010aa:	aaeff0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(p, mlk_polyvec, 1, context);
    800010ae:	8522                	mv	a0,s0
    800010b0:	40000593          	li	a1,1024
    800010b4:	aa4ff0ef          	jal	80000358 <mlk_zeroize>
  return ret;
}
    800010b8:	72813083          	ld	ra,1832(sp)
    800010bc:	72013403          	ld	s0,1824(sp)
  ret = mlk_ct_memcmp(pk, p_reencoded, MLKEM_POLYVECBYTES) ? MLK_ERR_FAIL : 0;
    800010c0:	01203533          	snez	a0,s2
}
    800010c4:	71813483          	ld	s1,1816(sp)
    800010c8:	71013903          	ld	s2,1808(sp)
    800010cc:	40a00533          	neg	a0,a0
    800010d0:	73010113          	addi	sp,sp,1840
    800010d4:	8082                	ret

00000000800010d6 <mlkem_shake128_init>:
                                mlk_shake128ctx *state)
{
  mlk_keccak_squeezeblocks(output, nblocks, state->ctx, SHAKE128_RATE);
}

void mlk_shake128_init(mlk_shake128ctx *state) { (void)state; }
    800010d6:	8082                	ret

00000000800010d8 <mlkem_shake128_release>:
void mlk_shake128_release(mlk_shake128ctx *state)
{
  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  mlk_zeroize(state, sizeof(mlk_shake128ctx));
    800010d8:	0e000593          	li	a1,224
    800010dc:	a7cff06f          	j	80000358 <mlk_zeroize>

00000000800010e0 <mlkem_shake128x4_init>:
{
  mlk_keccak_squeezeblocks_x4(out0, out1, out2, out3, nblocks, state->ctx,
                              SHAKE128_RATE);
}

void mlk_shake128x4_init(mlk_shake128x4ctx *state) { (void)state; }
    800010e0:	8082                	ret

00000000800010e2 <mlkem_shake128x4_release>:
void mlk_shake128x4_release(mlk_shake128x4ctx *state)
{
  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  mlk_zeroize(state, sizeof(mlk_shake128x4ctx));
    800010e2:	32000593          	li	a1,800
    800010e6:	a72ff06f          	j	80000358 <mlk_zeroize>

00000000800010ea <mlkem_keccakf1600_extract_bytes>:
  uint8_t *state_ptr = (uint8_t *)state + offset;
    800010ea:	1602                	slli	a2,a2,0x20
    800010ec:	9201                	srli	a2,a2,0x20
  for (i = 0; i < length; i++)
    800010ee:	4781                	li	a5,0
    800010f0:	0007871b          	sext.w	a4,a5
    800010f4:	00d76363          	bltu	a4,a3,800010fa <mlkem_keccakf1600_extract_bytes+0x10>
}
    800010f8:	8082                	ret
    data[i] = state_ptr[i];
    800010fa:	00f60733          	add	a4,a2,a5
    800010fe:	972a                	add	a4,a4,a0
    80001100:	00074803          	lbu	a6,0(a4)
    80001104:	00f58733          	add	a4,a1,a5
    80001108:	0785                	addi	a5,a5,1
    8000110a:	01070023          	sb	a6,0(a4)
  for (i = 0; i < length; i++)
    8000110e:	b7cd                	j	800010f0 <mlkem_keccakf1600_extract_bytes+0x6>

0000000080001110 <mlk_keccakf1600x4_extract_bytes_c>:
{
    80001110:	7139                	addi	sp,sp,-64
    80001112:	ec4e                	sd	s3,24(sp)
    80001114:	e852                	sd	s4,16(sp)
    80001116:	89b2                	mv	s3,a2
    80001118:	8a36                	mv	s4,a3
  mlk_keccakf1600_extract_bytes(state + MLK_KECCAK_LANES * 0, data0, offset,
    8000111a:	863e                	mv	a2,a5
    8000111c:	86c2                	mv	a3,a6
{
    8000111e:	fc06                	sd	ra,56(sp)
    80001120:	f822                	sd	s0,48(sp)
    80001122:	f426                	sd	s1,40(sp)
    80001124:	f04a                	sd	s2,32(sp)
    80001126:	84be                	mv	s1,a5
    80001128:	8942                	mv	s2,a6
    8000112a:	842a                	mv	s0,a0
    8000112c:	e43a                	sd	a4,8(sp)
  mlk_keccakf1600_extract_bytes(state + MLK_KECCAK_LANES * 0, data0, offset,
    8000112e:	fbdff0ef          	jal	800010ea <mlkem_keccakf1600_extract_bytes>
  mlk_keccakf1600_extract_bytes(state + MLK_KECCAK_LANES * 1, data1, offset,
    80001132:	86ca                	mv	a3,s2
    80001134:	8626                	mv	a2,s1
    80001136:	85ce                	mv	a1,s3
    80001138:	0c840513          	addi	a0,s0,200
    8000113c:	fafff0ef          	jal	800010ea <mlkem_keccakf1600_extract_bytes>
  mlk_keccakf1600_extract_bytes(state + MLK_KECCAK_LANES * 2, data2, offset,
    80001140:	86ca                	mv	a3,s2
    80001142:	8626                	mv	a2,s1
    80001144:	85d2                	mv	a1,s4
    80001146:	19040513          	addi	a0,s0,400
    8000114a:	fa1ff0ef          	jal	800010ea <mlkem_keccakf1600_extract_bytes>
  mlk_keccakf1600_extract_bytes(state + MLK_KECCAK_LANES * 3, data3, offset,
    8000114e:	25840513          	addi	a0,s0,600
}
    80001152:	7442                	ld	s0,48(sp)
  mlk_keccakf1600_extract_bytes(state + MLK_KECCAK_LANES * 3, data3, offset,
    80001154:	65a2                	ld	a1,8(sp)
}
    80001156:	70e2                	ld	ra,56(sp)
    80001158:	69e2                	ld	s3,24(sp)
    8000115a:	6a42                	ld	s4,16(sp)
  mlk_keccakf1600_extract_bytes(state + MLK_KECCAK_LANES * 3, data3, offset,
    8000115c:	86ca                	mv	a3,s2
    8000115e:	8626                	mv	a2,s1
}
    80001160:	7902                	ld	s2,32(sp)
    80001162:	74a2                	ld	s1,40(sp)
    80001164:	6121                	addi	sp,sp,64
  mlk_keccakf1600_extract_bytes(state + MLK_KECCAK_LANES * 3, data3, offset,
    80001166:	b751                	j	800010ea <mlkem_keccakf1600_extract_bytes>

0000000080001168 <mlk_keccak_squeeze_once>:
{
    80001168:	7179                	addi	sp,sp,-48
    8000116a:	f022                	sd	s0,32(sp)
    8000116c:	ec26                	sd	s1,24(sp)
    8000116e:	e44e                	sd	s3,8(sp)
    80001170:	e052                	sd	s4,0(sp)
    80001172:	f406                	sd	ra,40(sp)
    80001174:	e84a                	sd	s2,16(sp)
    80001176:	84aa                	mv	s1,a0
    80001178:	842e                	mv	s0,a1
    8000117a:	8a32                	mv	s4,a2
    8000117c:	89b6                	mv	s3,a3
  while (outlen > 0)
    8000117e:	e809                	bnez	s0,80001190 <mlk_keccak_squeeze_once+0x28>
}
    80001180:	70a2                	ld	ra,40(sp)
    80001182:	7402                	ld	s0,32(sp)
    80001184:	64e2                	ld	s1,24(sp)
    80001186:	6942                	ld	s2,16(sp)
    80001188:	69a2                	ld	s3,8(sp)
    8000118a:	6a02                	ld	s4,0(sp)
    8000118c:	6145                	addi	sp,sp,48
    8000118e:	8082                	ret
  if (mlk_keccak_f1600_x1_native(state) == MLK_NATIVE_FUNC_SUCCESS)
  {
    return;
  }
#endif /* MLK_USE_FIPS202_X1_NATIVE */
  mlk_keccakf1600_permute_c(state);
    80001190:	8552                	mv	a0,s4
    80001192:	bfeff0ef          	jal	80000590 <mlk_keccakf1600_permute_c>
    if (outlen < r)
    80001196:	894e                	mv	s2,s3
    80001198:	01347363          	bgeu	s0,s3,8000119e <mlk_keccak_squeeze_once+0x36>
    8000119c:	8922                	mv	s2,s0
    mlk_keccakf1600_extract_bytes(s, h, 0, (unsigned int)len);
    8000119e:	85a6                	mv	a1,s1
    800011a0:	0009069b          	sext.w	a3,s2
    800011a4:	4601                	li	a2,0
    800011a6:	8552                	mv	a0,s4
    800011a8:	f43ff0ef          	jal	800010ea <mlkem_keccakf1600_extract_bytes>
    h += len;
    800011ac:	94ca                	add	s1,s1,s2
    outlen -= len;
    800011ae:	41240433          	sub	s0,s0,s2
    800011b2:	b7f1                	j	8000117e <mlk_keccak_squeeze_once+0x16>

00000000800011b4 <mlkem_shake128_squeezeblocks>:
{
    800011b4:	1101                	addi	sp,sp,-32
    800011b6:	e822                	sd	s0,16(sp)
    800011b8:	e426                	sd	s1,8(sp)
    800011ba:	e04a                	sd	s2,0(sp)
    800011bc:	ec06                	sd	ra,24(sp)
    800011be:	84aa                	mv	s1,a0
    800011c0:	842e                	mv	s0,a1
    800011c2:	8932                	mv	s2,a2
  while (nblocks > 0)
    800011c4:	e419                	bnez	s0,800011d2 <mlkem_shake128_squeezeblocks+0x1e>
}
    800011c6:	60e2                	ld	ra,24(sp)
    800011c8:	6442                	ld	s0,16(sp)
    800011ca:	64a2                	ld	s1,8(sp)
    800011cc:	6902                	ld	s2,0(sp)
    800011ce:	6105                	addi	sp,sp,32
    800011d0:	8082                	ret
    800011d2:	854a                	mv	a0,s2
    800011d4:	bbcff0ef          	jal	80000590 <mlk_keccakf1600_permute_c>
    mlk_keccakf1600_extract_bytes(s, h, 0, r);
    800011d8:	85a6                	mv	a1,s1
    800011da:	0a800693          	li	a3,168
    800011de:	4601                	li	a2,0
    800011e0:	854a                	mv	a0,s2
    800011e2:	f09ff0ef          	jal	800010ea <mlkem_keccakf1600_extract_bytes>
    h += r;
    800011e6:	0a848493          	addi	s1,s1,168
    nblocks--;
    800011ea:	147d                	addi	s0,s0,-1
    800011ec:	bfe1                	j	800011c4 <mlkem_shake128_squeezeblocks+0x10>

00000000800011ee <mlkem_keccakf1600_xor_bytes>:
  uint8_t *state_ptr = (uint8_t *)state + offset;
    800011ee:	1602                	slli	a2,a2,0x20
    800011f0:	9201                	srli	a2,a2,0x20
    800011f2:	9532                	add	a0,a0,a2
  for (i = 0; i < length; i++)
    800011f4:	4781                	li	a5,0
    800011f6:	0007871b          	sext.w	a4,a5
    800011fa:	00d76363          	bltu	a4,a3,80001200 <mlkem_keccakf1600_xor_bytes+0x12>
}
    800011fe:	8082                	ret
    state_ptr[i] ^= data[i];
    80001200:	00f58733          	add	a4,a1,a5
    80001204:	00054603          	lbu	a2,0(a0)
    80001208:	00074703          	lbu	a4,0(a4)
    8000120c:	0785                	addi	a5,a5,1
    8000120e:	0505                	addi	a0,a0,1
    80001210:	8f31                	xor	a4,a4,a2
    80001212:	fee50fa3          	sb	a4,-1(a0)
  for (i = 0; i < length; i++)
    80001216:	b7c5                	j	800011f6 <mlkem_keccakf1600_xor_bytes+0x8>

0000000080001218 <mlk_keccakf1600x4_xor_bytes_c>:
{
    80001218:	7139                	addi	sp,sp,-64
    8000121a:	ec4e                	sd	s3,24(sp)
    8000121c:	e852                	sd	s4,16(sp)
    8000121e:	89b2                	mv	s3,a2
    80001220:	8a36                	mv	s4,a3
  mlk_keccakf1600_xor_bytes(state + MLK_KECCAK_LANES * 0, data0, offset,
    80001222:	863e                	mv	a2,a5
    80001224:	86c2                	mv	a3,a6
{
    80001226:	fc06                	sd	ra,56(sp)
    80001228:	f822                	sd	s0,48(sp)
    8000122a:	f426                	sd	s1,40(sp)
    8000122c:	f04a                	sd	s2,32(sp)
    8000122e:	84be                	mv	s1,a5
    80001230:	8942                	mv	s2,a6
    80001232:	842a                	mv	s0,a0
    80001234:	e43a                	sd	a4,8(sp)
  mlk_keccakf1600_xor_bytes(state + MLK_KECCAK_LANES * 0, data0, offset,
    80001236:	fb9ff0ef          	jal	800011ee <mlkem_keccakf1600_xor_bytes>
  mlk_keccakf1600_xor_bytes(state + MLK_KECCAK_LANES * 1, data1, offset,
    8000123a:	86ca                	mv	a3,s2
    8000123c:	8626                	mv	a2,s1
    8000123e:	85ce                	mv	a1,s3
    80001240:	0c840513          	addi	a0,s0,200
    80001244:	fabff0ef          	jal	800011ee <mlkem_keccakf1600_xor_bytes>
  mlk_keccakf1600_xor_bytes(state + MLK_KECCAK_LANES * 2, data2, offset,
    80001248:	86ca                	mv	a3,s2
    8000124a:	8626                	mv	a2,s1
    8000124c:	85d2                	mv	a1,s4
    8000124e:	19040513          	addi	a0,s0,400
    80001252:	f9dff0ef          	jal	800011ee <mlkem_keccakf1600_xor_bytes>
  mlk_keccakf1600_xor_bytes(state + MLK_KECCAK_LANES * 3, data3, offset,
    80001256:	25840513          	addi	a0,s0,600
}
    8000125a:	7442                	ld	s0,48(sp)
  mlk_keccakf1600_xor_bytes(state + MLK_KECCAK_LANES * 3, data3, offset,
    8000125c:	65a2                	ld	a1,8(sp)
}
    8000125e:	70e2                	ld	ra,56(sp)
    80001260:	69e2                	ld	s3,24(sp)
    80001262:	6a42                	ld	s4,16(sp)
  mlk_keccakf1600_xor_bytes(state + MLK_KECCAK_LANES * 3, data3, offset,
    80001264:	86ca                	mv	a3,s2
    80001266:	8626                	mv	a2,s1
}
    80001268:	7902                	ld	s2,32(sp)
    8000126a:	74a2                	ld	s1,40(sp)
    8000126c:	6121                	addi	sp,sp,64
  mlk_keccakf1600_xor_bytes(state + MLK_KECCAK_LANES * 3, data3, offset,
    8000126e:	b741                	j	800011ee <mlkem_keccakf1600_xor_bytes>

0000000080001270 <mlk_keccak_absorb_once>:
{
    80001270:	7179                	addi	sp,sp,-48
    80001272:	ec26                	sd	s1,24(sp)
    80001274:	00e107a3          	sb	a4,15(sp)
    80001278:	f406                	sd	ra,40(sp)
    8000127a:	f022                	sd	s0,32(sp)
    8000127c:	e84a                	sd	s2,16(sp)
    8000127e:	84ae                	mv	s1,a1
  for (i = 0; i < 25; ++i)
    80001280:	87aa                	mv	a5,a0
    80001282:	0c850713          	addi	a4,a0,200
    s[i] = 0;
    80001286:	0007b023          	sd	zero,0(a5)
  for (i = 0; i < 25; ++i)
    8000128a:	07a1                	addi	a5,a5,8
    8000128c:	fee79de3          	bne	a5,a4,80001286 <mlk_keccak_absorb_once+0x16>
  while (mlen >= r)
    80001290:	8436                	mv	s0,a3
    80001292:	00d60933          	add	s2,a2,a3
    80001296:	408905b3          	sub	a1,s2,s0
    8000129a:	04947063          	bgeu	s0,s1,800012da <mlk_keccak_absorb_once+0x6a>
    mlk_keccakf1600_xor_bytes(s, m, 0, (unsigned int)mlen);
    8000129e:	0004091b          	sext.w	s2,s0
  if (mlen == r - 1)
    800012a2:	34fd                	addiw	s1,s1,-1
  if (mlen > 0)
    800012a4:	c431                	beqz	s0,800012f0 <mlk_keccak_absorb_once+0x80>
    mlk_keccakf1600_xor_bytes(s, m, 0, (unsigned int)mlen);
    800012a6:	86ca                	mv	a3,s2
    800012a8:	4601                	li	a2,0
    800012aa:	e02a                	sd	a0,0(sp)
    800012ac:	f43ff0ef          	jal	800011ee <mlkem_keccakf1600_xor_bytes>
  if (mlen == r - 1)
    800012b0:	6502                	ld	a0,0(sp)
    800012b2:	02849f63          	bne	s1,s0,800012f0 <mlk_keccak_absorb_once+0x80>
    p |= 128;
    800012b6:	00f14783          	lbu	a5,15(sp)
    mlk_keccakf1600_xor_bytes(s, &p, (unsigned int)mlen, 1);
    800012ba:	4685                	li	a3,1
    800012bc:	864a                	mv	a2,s2
    p |= 128;
    800012be:	f807e793          	ori	a5,a5,-128
    800012c2:	00f107a3          	sb	a5,15(sp)
    mlk_keccakf1600_xor_bytes(s, &p, (unsigned int)mlen, 1);
    800012c6:	00f10593          	addi	a1,sp,15
    mlk_keccakf1600_xor_bytes(s, &p, r - 1, 1);
    800012ca:	f25ff0ef          	jal	800011ee <mlkem_keccakf1600_xor_bytes>
}
    800012ce:	70a2                	ld	ra,40(sp)
    800012d0:	7402                	ld	s0,32(sp)
    800012d2:	64e2                	ld	s1,24(sp)
    800012d4:	6942                	ld	s2,16(sp)
    800012d6:	6145                	addi	sp,sp,48
    800012d8:	8082                	ret
    mlk_keccakf1600_xor_bytes(s, m, 0, r);
    800012da:	86a6                	mv	a3,s1
    800012dc:	4601                	li	a2,0
    800012de:	e02a                	sd	a0,0(sp)
    800012e0:	f0fff0ef          	jal	800011ee <mlkem_keccakf1600_xor_bytes>
  mlk_keccakf1600_permute_c(state);
    800012e4:	6502                	ld	a0,0(sp)
    mlen -= r;
    800012e6:	8c05                	sub	s0,s0,s1
    800012e8:	aa8ff0ef          	jal	80000590 <mlk_keccakf1600_permute_c>
    800012ec:	6502                	ld	a0,0(sp)
    m += r;
    800012ee:	b765                	j	80001296 <mlk_keccak_absorb_once+0x26>
    mlk_keccakf1600_xor_bytes(s, &p, (unsigned int)mlen, 1);
    800012f0:	4685                	li	a3,1
    800012f2:	864a                	mv	a2,s2
    800012f4:	00f10593          	addi	a1,sp,15
    800012f8:	e02a                	sd	a0,0(sp)
    800012fa:	ef5ff0ef          	jal	800011ee <mlkem_keccakf1600_xor_bytes>
    p = 128;
    800012fe:	f8000793          	li	a5,-128
    mlk_keccakf1600_xor_bytes(s, &p, r - 1, 1);
    80001302:	6502                	ld	a0,0(sp)
    p = 128;
    80001304:	00f107a3          	sb	a5,15(sp)
    mlk_keccakf1600_xor_bytes(s, &p, r - 1, 1);
    80001308:	4685                	li	a3,1
    8000130a:	8626                	mv	a2,s1
    8000130c:	00f10593          	addi	a1,sp,15
    80001310:	bf6d                	j	800012ca <mlk_keccak_absorb_once+0x5a>

0000000080001312 <mlkem_shake128_absorb_once>:
{
    80001312:	86b2                	mv	a3,a2
  mlk_keccak_absorb_once(state->ctx, SHAKE128_RATE, input, inlen, 0x1F);
    80001314:	477d                	li	a4,31
    80001316:	862e                	mv	a2,a1
    80001318:	0a800593          	li	a1,168
    8000131c:	bf91                	j	80001270 <mlk_keccak_absorb_once>

000000008000131e <mlkem_shake256>:
}

typedef mlk_shake128ctx mlk_shake256ctx;
void mlk_shake256(uint8_t *output, size_t outlen, const uint8_t *input,
                  size_t inlen)
{
    8000131e:	716d                	addi	sp,sp,-272
    80001320:	01f10793          	addi	a5,sp,31
    80001324:	e222                	sd	s0,256(sp)
    80001326:	fe07f413          	andi	s0,a5,-32
    8000132a:	fda6                	sd	s1,248(sp)
    8000132c:	f9ca                	sd	s2,240(sp)
    8000132e:	84aa                	mv	s1,a0
    80001330:	892e                	mv	s2,a1
  mlk_shake256ctx state;
  /* Absorb input */
  mlk_keccak_absorb_once(state.ctx, SHAKE256_RATE, input, inlen, 0x1F);
    80001332:	477d                	li	a4,31
    80001334:	8522                	mv	a0,s0
    80001336:	08800593          	li	a1,136
{
    8000133a:	e606                	sd	ra,264(sp)
  mlk_keccak_absorb_once(state.ctx, SHAKE256_RATE, input, inlen, 0x1F);
    8000133c:	f35ff0ef          	jal	80001270 <mlk_keccak_absorb_once>
  /* Squeeze output */
  mlk_keccak_squeeze_once(output, outlen, state.ctx, SHAKE256_RATE);
    80001340:	8622                	mv	a2,s0
    80001342:	85ca                	mv	a1,s2
    80001344:	8526                	mv	a0,s1
    80001346:	08800693          	li	a3,136
    8000134a:	e1fff0ef          	jal	80001168 <mlk_keccak_squeeze_once>
  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  mlk_zeroize(&state, sizeof(state));
    8000134e:	8522                	mv	a0,s0
    80001350:	0e000593          	li	a1,224
    80001354:	804ff0ef          	jal	80000358 <mlk_zeroize>
}
    80001358:	60b2                	ld	ra,264(sp)
    8000135a:	6412                	ld	s0,256(sp)
    8000135c:	74ee                	ld	s1,248(sp)
    8000135e:	794e                	ld	s2,240(sp)
    80001360:	6151                	addi	sp,sp,272
    80001362:	8082                	ret

0000000080001364 <mlkem_sha3_256>:

void mlk_sha3_256(uint8_t *output, const uint8_t *input, size_t inlen)
{
    80001364:	7115                	addi	sp,sp,-224
    80001366:	e9a2                	sd	s0,208(sp)
    80001368:	86b2                	mv	a3,a2
    8000136a:	842a                	mv	s0,a0
  uint64_t ctx[25];
  /* Absorb input */
  mlk_keccak_absorb_once(ctx, SHA3_256_RATE, input, inlen, 0x06);
    8000136c:	4719                	li	a4,6
    8000136e:	862e                	mv	a2,a1
    80001370:	0028                	addi	a0,sp,8
    80001372:	08800593          	li	a1,136
{
    80001376:	ed86                	sd	ra,216(sp)
  mlk_keccak_absorb_once(ctx, SHA3_256_RATE, input, inlen, 0x06);
    80001378:	ef9ff0ef          	jal	80001270 <mlk_keccak_absorb_once>
  /* Squeeze output */
  mlk_keccak_squeeze_once(output, 32, ctx, SHA3_256_RATE);
    8000137c:	0030                	addi	a2,sp,8
    8000137e:	8522                	mv	a0,s0
    80001380:	08800693          	li	a3,136
    80001384:	02000593          	li	a1,32
    80001388:	de1ff0ef          	jal	80001168 <mlk_keccak_squeeze_once>
  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  mlk_zeroize(ctx, sizeof(ctx));
    8000138c:	0028                	addi	a0,sp,8
    8000138e:	0c800593          	li	a1,200
    80001392:	fc7fe0ef          	jal	80000358 <mlk_zeroize>
}
    80001396:	60ee                	ld	ra,216(sp)
    80001398:	644e                	ld	s0,208(sp)
    8000139a:	612d                	addi	sp,sp,224
    8000139c:	8082                	ret

000000008000139e <mlkem_check_sk>:
/* Reference: Not implemented in the reference implementation @[REF]. */
MLK_EXTERNAL_API
MLK_MUST_CHECK_RETURN_VALUE
int mlk_kem_check_sk(const uint8_t sk[MLKEM_INDCCA_SECRETKEYBYTES],
                     MLK_CONFIG_CONTEXT_PARAMETER_TYPE context)
{
    8000139e:	715d                	addi	sp,sp,-80
    800013a0:	01f10793          	addi	a5,sp,31
    800013a4:	fc26                	sd	s1,56(sp)
    800013a6:	fe07f493          	andi	s1,a5,-32
    800013aa:	e0a2                	sd	s0,64(sp)
  MLK_CT_TESTING_DECLASSIFY(sk + MLKEM_INDCPA_SECRETKEYBYTES,
                            MLKEM_INDCCA_PUBLICKEYBYTES);
  MLK_CT_TESTING_DECLASSIFY(
      sk + MLKEM_INDCCA_SECRETKEYBYTES - 2 * MLKEM_SYMBYTES, MLKEM_SYMBYTES);

  mlk_hash_h(test, sk + MLKEM_INDCPA_SECRETKEYBYTES,
    800013ac:	30050593          	addi	a1,a0,768
{
    800013b0:	842a                	mv	s0,a0
  mlk_hash_h(test, sk + MLKEM_INDCPA_SECRETKEYBYTES,
    800013b2:	32000613          	li	a2,800
    800013b6:	8526                	mv	a0,s1
{
    800013b8:	e486                	sd	ra,72(sp)
  mlk_hash_h(test, sk + MLKEM_INDCPA_SECRETKEYBYTES,
    800013ba:	fabff0ef          	jal	80001364 <mlkem_sha3_256>
             MLKEM_INDCCA_PUBLICKEYBYTES);
  /* This doesn't have to be a constant-time memcmp, but it's the only place
   * in the library where a normal memcmp would be used otherwise, so for sake
   * of minimizing stdlib dependency, we use our constant-time one anyway. */
  ret = mlk_ct_memcmp(sk + MLKEM_INDCCA_SECRETKEYBYTES - 2 * MLKEM_SYMBYTES,
    800013be:	85a6                	mv	a1,s1
    800013c0:	02000613          	li	a2,32
    800013c4:	62040513          	addi	a0,s0,1568
    800013c8:	c5dff0ef          	jal	80001024 <mlk_ct_memcmp>
    800013cc:	842a                	mv	s0,a0
            : 0;

cleanup:
  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  MLK_FREE(test, uint8_t, MLKEM_SYMBYTES, context);
    800013ce:	02000593          	li	a1,32
    800013d2:	8526                	mv	a0,s1
    800013d4:	f85fe0ef          	jal	80000358 <mlk_zeroize>
  return ret;
}
    800013d8:	60a6                	ld	ra,72(sp)
            : 0;
    800013da:	00803533          	snez	a0,s0
}
    800013de:	6406                	ld	s0,64(sp)
    800013e0:	74e2                	ld	s1,56(sp)
    800013e2:	40a00533          	neg	a0,a0
    800013e6:	6161                	addi	sp,sp,80
    800013e8:	8082                	ret

00000000800013ea <mlkem_sha3_512>:

void mlk_sha3_512(uint8_t *output, const uint8_t *input, size_t inlen)
{
    800013ea:	7115                	addi	sp,sp,-224
    800013ec:	e9a2                	sd	s0,208(sp)
    800013ee:	86b2                	mv	a3,a2
    800013f0:	842a                	mv	s0,a0
  uint64_t ctx[25];
  /* Absorb input */
  mlk_keccak_absorb_once(ctx, SHA3_512_RATE, input, inlen, 0x06);
    800013f2:	4719                	li	a4,6
    800013f4:	862e                	mv	a2,a1
    800013f6:	0028                	addi	a0,sp,8
    800013f8:	04800593          	li	a1,72
{
    800013fc:	ed86                	sd	ra,216(sp)
  mlk_keccak_absorb_once(ctx, SHA3_512_RATE, input, inlen, 0x06);
    800013fe:	e73ff0ef          	jal	80001270 <mlk_keccak_absorb_once>
  /* Squeeze output */
  mlk_keccak_squeeze_once(output, 64, ctx, SHA3_512_RATE);
    80001402:	0030                	addi	a2,sp,8
    80001404:	8522                	mv	a0,s0
    80001406:	04800693          	li	a3,72
    8000140a:	04000593          	li	a1,64
    8000140e:	d5bff0ef          	jal	80001168 <mlk_keccak_squeeze_once>
  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  mlk_zeroize(ctx, sizeof(ctx));
    80001412:	0028                	addi	a0,sp,8
    80001414:	0c800593          	li	a1,200
    80001418:	f41fe0ef          	jal	80000358 <mlk_zeroize>
}
    8000141c:	60ee                	ld	ra,216(sp)
    8000141e:	644e                	ld	s0,208(sp)
    80001420:	612d                	addi	sp,sp,224
    80001422:	8082                	ret

0000000080001424 <mlkem_keccakf1600x4_extract_bytes>:
  mlk_keccakf1600x4_extract_bytes_c(state, data0, data1, data2, data3, offset,
    80001424:	b1f5                	j	80001110 <mlk_keccakf1600x4_extract_bytes_c>

0000000080001426 <mlkem_keccakf1600x4_xor_bytes>:
  mlk_keccakf1600x4_xor_bytes_c(state, data0, data1, data2, data3, offset,
    80001426:	bbcd                	j	80001218 <mlk_keccakf1600x4_xor_bytes_c>

0000000080001428 <mlkem_keccakf1600x4_permute>:
{
    80001428:	1141                	addi	sp,sp,-16
    8000142a:	e406                	sd	ra,8(sp)
    8000142c:	e022                	sd	s0,0(sp)
    8000142e:	842a                	mv	s0,a0
  mlk_keccakf1600_permute_c(state);
    80001430:	960ff0ef          	jal	80000590 <mlk_keccakf1600_permute_c>
    80001434:	0c840513          	addi	a0,s0,200
    80001438:	958ff0ef          	jal	80000590 <mlk_keccakf1600_permute_c>
    8000143c:	19040513          	addi	a0,s0,400
    80001440:	950ff0ef          	jal	80000590 <mlk_keccakf1600_permute_c>
    80001444:	25840513          	addi	a0,s0,600
}
    80001448:	6402                	ld	s0,0(sp)
    8000144a:	60a2                	ld	ra,8(sp)
    8000144c:	0141                	addi	sp,sp,16
  mlk_keccakf1600_permute_c(state);
    8000144e:	942ff06f          	j	80000590 <mlk_keccakf1600_permute_c>

0000000080001452 <mlk_keccak_squeezeblocks_x4>:
{
    80001452:	715d                	addi	sp,sp,-80
    80001454:	e0a2                	sd	s0,64(sp)
    80001456:	fc26                	sd	s1,56(sp)
    80001458:	f84a                	sd	s2,48(sp)
    8000145a:	f44e                	sd	s3,40(sp)
    8000145c:	f052                	sd	s4,32(sp)
    8000145e:	ec56                	sd	s5,24(sp)
    80001460:	e486                	sd	ra,72(sp)
    80001462:	843a                	mv	s0,a4
    80001464:	8abe                	mv	s5,a5
    80001466:	84aa                	mv	s1,a0
    80001468:	892e                	mv	s2,a1
    8000146a:	89b2                	mv	s3,a2
    8000146c:	8a36                	mv	s4,a3
  while (nblocks > 0)
    8000146e:	e811                	bnez	s0,80001482 <mlk_keccak_squeezeblocks_x4+0x30>
}
    80001470:	60a6                	ld	ra,72(sp)
    80001472:	6406                	ld	s0,64(sp)
    80001474:	74e2                	ld	s1,56(sp)
    80001476:	7942                	ld	s2,48(sp)
    80001478:	79a2                	ld	s3,40(sp)
    8000147a:	7a02                	ld	s4,32(sp)
    8000147c:	6ae2                	ld	s5,24(sp)
    8000147e:	6161                	addi	sp,sp,80
    80001480:	8082                	ret
    mlk_keccakf1600x4_permute(s);
    80001482:	8556                	mv	a0,s5
    80001484:	e442                	sd	a6,8(sp)
    80001486:	fa3ff0ef          	jal	80001428 <mlkem_keccakf1600x4_permute>
  mlk_keccakf1600x4_extract_bytes_c(state, data0, data1, data2, data3, offset,
    8000148a:	6822                	ld	a6,8(sp)
    8000148c:	8752                	mv	a4,s4
    8000148e:	86ce                	mv	a3,s3
    80001490:	864a                	mv	a2,s2
    80001492:	85a6                	mv	a1,s1
    80001494:	4781                	li	a5,0
    80001496:	8556                	mv	a0,s5
    80001498:	c79ff0ef          	jal	80001110 <mlk_keccakf1600x4_extract_bytes_c>
    nblocks--;
    8000149c:	6822                	ld	a6,8(sp)
    8000149e:	147d                	addi	s0,s0,-1
    800014a0:	94c2                	add	s1,s1,a6
    800014a2:	9942                	add	s2,s2,a6
    800014a4:	99c2                	add	s3,s3,a6
    800014a6:	9a42                	add	s4,s4,a6
    800014a8:	b7d9                	j	8000146e <mlk_keccak_squeezeblocks_x4+0x1c>

00000000800014aa <mlkem_shake128x4_squeezeblocks>:
  mlk_keccak_squeezeblocks_x4(out0, out1, out2, out3, nblocks, state->ctx,
    800014aa:	0a800813          	li	a6,168
    800014ae:	b755                	j	80001452 <mlk_keccak_squeezeblocks_x4>

00000000800014b0 <mlk_keccak_absorb_once_x4.constprop.0>:
static void mlk_keccak_absorb_once_x4(uint64_t *s, unsigned r,
    800014b0:	7159                	addi	sp,sp,-112
    800014b2:	f85a                	sd	s6,48(sp)
    800014b4:	8b3e                	mv	s6,a5
    800014b6:	47fd                	li	a5,31
    800014b8:	f0a2                	sd	s0,96(sp)
    800014ba:	eca6                	sd	s1,88(sp)
    800014bc:	e4ce                	sd	s3,72(sp)
    800014be:	e0d2                	sd	s4,64(sp)
    800014c0:	fc56                	sd	s5,56(sp)
    800014c2:	f45e                	sd	s7,40(sp)
    800014c4:	f486                	sd	ra,104(sp)
    800014c6:	e8ca                	sd	s2,80(sp)
    800014c8:	842e                	mv	s0,a1
    800014ca:	89b2                	mv	s3,a2
    800014cc:	8a36                	mv	s4,a3
    800014ce:	8aba                	mv	s5,a4
    800014d0:	8bc2                	mv	s7,a6
    800014d2:	00f10fa3          	sb	a5,31(sp)
  while (inlen >= r)
    800014d6:	4481                	li	s1,0
    800014d8:	409b8933          	sub	s2,s7,s1
    800014dc:	009b0733          	add	a4,s6,s1
    800014e0:	009a86b3          	add	a3,s5,s1
    800014e4:	009a0633          	add	a2,s4,s1
    800014e8:	009985b3          	add	a1,s3,s1
    800014ec:	04897763          	bgeu	s2,s0,8000153a <mlk_keccak_absorb_once_x4.constprop.0+0x8a>
  if (inlen == r - 1)
    800014f0:	347d                	addiw	s0,s0,-1
  if (inlen > 0)
    800014f2:	04090f63          	beqz	s2,80001550 <mlk_keccak_absorb_once_x4.constprop.0+0xa0>
  mlk_keccakf1600x4_xor_bytes_c(state, data0, data1, data2, data3, offset,
    800014f6:	0009081b          	sext.w	a6,s2
    800014fa:	4781                	li	a5,0
    800014fc:	e42a                	sd	a0,8(sp)
    800014fe:	d1bff0ef          	jal	80001218 <mlk_keccakf1600x4_xor_bytes_c>
  if (inlen == r - 1)
    80001502:	6522                	ld	a0,8(sp)
    80001504:	04891663          	bne	s2,s0,80001550 <mlk_keccak_absorb_once_x4.constprop.0+0xa0>
    80001508:	01f10713          	addi	a4,sp,31
    p |= 128;
    8000150c:	f9f00793          	li	a5,-97
    80001510:	00f10fa3          	sb	a5,31(sp)
    80001514:	4805                	li	a6,1
    80001516:	0009079b          	sext.w	a5,s2
    8000151a:	86ba                	mv	a3,a4
    8000151c:	863a                	mv	a2,a4
    8000151e:	85ba                	mv	a1,a4
    80001520:	cf9ff0ef          	jal	80001218 <mlk_keccakf1600x4_xor_bytes_c>
}
    80001524:	70a6                	ld	ra,104(sp)
    80001526:	7406                	ld	s0,96(sp)
    80001528:	64e6                	ld	s1,88(sp)
    8000152a:	6946                	ld	s2,80(sp)
    8000152c:	69a6                	ld	s3,72(sp)
    8000152e:	6a06                	ld	s4,64(sp)
    80001530:	7ae2                	ld	s5,56(sp)
    80001532:	7b42                	ld	s6,48(sp)
    80001534:	7ba2                	ld	s7,40(sp)
    80001536:	6165                	addi	sp,sp,112
    80001538:	8082                	ret
    8000153a:	8822                	mv	a6,s0
    8000153c:	4781                	li	a5,0
    8000153e:	e42a                	sd	a0,8(sp)
    80001540:	cd9ff0ef          	jal	80001218 <mlk_keccakf1600x4_xor_bytes_c>
    mlk_keccakf1600x4_permute(s);
    80001544:	6522                	ld	a0,8(sp)
    80001546:	94a2                	add	s1,s1,s0
    80001548:	ee1ff0ef          	jal	80001428 <mlkem_keccakf1600x4_permute>
    inlen -= r;
    8000154c:	6522                	ld	a0,8(sp)
    8000154e:	b769                	j	800014d8 <mlk_keccak_absorb_once_x4.constprop.0+0x28>
    80001550:	01f10713          	addi	a4,sp,31
    80001554:	86ba                	mv	a3,a4
    80001556:	863a                	mv	a2,a4
    80001558:	85ba                	mv	a1,a4
    8000155a:	4805                	li	a6,1
    8000155c:	0009079b          	sext.w	a5,s2
    80001560:	e42a                	sd	a0,8(sp)
    80001562:	cb7ff0ef          	jal	80001218 <mlk_keccakf1600x4_xor_bytes_c>
    80001566:	01f10713          	addi	a4,sp,31
    p = 128;
    8000156a:	f8000793          	li	a5,-128
    8000156e:	00f10fa3          	sb	a5,31(sp)
    80001572:	6522                	ld	a0,8(sp)
    80001574:	4805                	li	a6,1
    80001576:	87a2                	mv	a5,s0
    80001578:	86ba                	mv	a3,a4
    8000157a:	863a                	mv	a2,a4
    8000157c:	85ba                	mv	a1,a4
    8000157e:	b74d                	j	80001520 <mlk_keccak_absorb_once_x4.constprop.0+0x70>

0000000080001580 <mlkem_shake256x4>:
}

void mlk_shake256x4(uint8_t *out0, uint8_t *out1, uint8_t *out2, uint8_t *out3,
                    size_t outlen, const uint8_t *in0, const uint8_t *in1,
                    const uint8_t *in2, const uint8_t *in3, size_t inlen)
{
    80001580:	a5010113          	addi	sp,sp,-1456
    80001584:	59213823          	sd	s2,1424(sp)
  mlk_shake256x4_ctx statex;
  size_t nblocks = outlen / SHAKE256_RATE;
    80001588:	08800913          	li	s2,136
{
    8000158c:	58913c23          	sd	s1,1432(sp)
  size_t nblocks = outlen / SHAKE256_RATE;
    80001590:	032754b3          	divu	s1,a4,s2
{
    80001594:	57813023          	sd	s8,1376(sp)
    80001598:	8c3e                	mv	s8,a5
    8000159a:	24f10793          	addi	a5,sp,591
    8000159e:	59313423          	sd	s3,1416(sp)
    800015a2:	fe07f993          	andi	s3,a5,-32
    800015a6:	59413023          	sd	s4,1408(sp)
    800015aa:	57513c23          	sd	s5,1400(sp)
    800015ae:	57613823          	sd	s6,1392(sp)
    800015b2:	8a2a                	mv	s4,a0
    800015b4:	8aae                	mv	s5,a1
    800015b6:	8b32                	mv	s6,a2
  mlk_memset(state, 0, sizeof(mlk_shake128x4ctx));
    800015b8:	4581                	li	a1,0
    800015ba:	32000613          	li	a2,800
    800015be:	854e                	mv	a0,s3
{
    800015c0:	5a113423          	sd	ra,1448(sp)
    800015c4:	e046                	sd	a7,0(sp)
    800015c6:	5a813023          	sd	s0,1440(sp)
    800015ca:	57713423          	sd	s7,1384(sp)
    800015ce:	843a                	mv	s0,a4
    800015d0:	8bb6                	mv	s7,a3
    800015d2:	e442                	sd	a6,8(sp)
  mlk_memset(state, 0, sizeof(mlk_shake128x4ctx));
    800015d4:	ca1fe0ef          	jal	80000274 <memset>
  mlk_keccak_absorb_once_x4(state->ctx, SHAKE256_RATE, in0, in1, in2, in3,
    800015d8:	5b813803          	ld	a6,1464(sp)
    800015dc:	5b013783          	ld	a5,1456(sp)
    800015e0:	6702                	ld	a4,0(sp)
    800015e2:	66a2                	ld	a3,8(sp)
    800015e4:	8662                	mv	a2,s8
    800015e6:	85ca                	mv	a1,s2
    800015e8:	854e                	mv	a0,s3
    800015ea:	ec7ff0ef          	jal	800014b0 <mlk_keccak_absorb_once_x4.constprop.0>
  mlk_keccak_squeezeblocks_x4(out0, out1, out2, out3, nblocks, state->ctx,
    800015ee:	884a                	mv	a6,s2
    800015f0:	87ce                	mv	a5,s3
    800015f2:	86de                	mv	a3,s7
    800015f4:	865a                	mv	a2,s6
    800015f6:	85d6                	mv	a1,s5
    800015f8:	8552                	mv	a0,s4
    800015fa:	8726                	mv	a4,s1
    800015fc:	e57ff0ef          	jal	80001452 <mlk_keccak_squeezeblocks_x4>
  out0 += nblocks * SHAKE256_RATE;
  out1 += nblocks * SHAKE256_RATE;
  out2 += nblocks * SHAKE256_RATE;
  out3 += nblocks * SHAKE256_RATE;

  outlen -= nblocks * SHAKE256_RATE;
    80001600:	03247433          	remu	s0,s0,s2

  if (outlen)
    80001604:	c429                	beqz	s0,8000164e <mlkem_shake256x4+0xce>
  out0 += nblocks * SHAKE256_RATE;
    80001606:	03248733          	mul	a4,s1,s2
  mlk_keccak_squeezeblocks_x4(out0, out1, out2, out3, nblocks, state->ctx,
    8000160a:	884a                	mv	a6,s2
    8000160c:	87ce                	mv	a5,s3
    8000160e:	1334                	addi	a3,sp,424
    80001610:	1210                	addi	a2,sp,288
    80001612:	092c                	addi	a1,sp,152
    80001614:	0808                	addi	a0,sp,16
  out0 += nblocks * SHAKE256_RATE;
    80001616:	9a3a                	add	s4,s4,a4
  out1 += nblocks * SHAKE256_RATE;
    80001618:	9aba                	add	s5,s5,a4
  out2 += nblocks * SHAKE256_RATE;
    8000161a:	9b3a                	add	s6,s6,a4
  out3 += nblocks * SHAKE256_RATE;
    8000161c:	00eb84b3          	add	s1,s7,a4
  mlk_keccak_squeezeblocks_x4(out0, out1, out2, out3, nblocks, state->ctx,
    80001620:	4705                	li	a4,1
    80001622:	e31ff0ef          	jal	80001452 <mlk_keccak_squeezeblocks_x4>
  {
    mlk_shake256x4_squeezeblocks(tmp0, tmp1, tmp2, tmp3, 1, &statex);
    mlk_memcpy(out0, tmp0, outlen);
    80001626:	8622                	mv	a2,s0
    80001628:	080c                	addi	a1,sp,16
    8000162a:	8552                	mv	a0,s4
    8000162c:	c2dfe0ef          	jal	80000258 <memcpy>
    mlk_memcpy(out1, tmp1, outlen);
    80001630:	8622                	mv	a2,s0
    80001632:	092c                	addi	a1,sp,152
    80001634:	8556                	mv	a0,s5
    80001636:	c23fe0ef          	jal	80000258 <memcpy>
    mlk_memcpy(out2, tmp2, outlen);
    8000163a:	8622                	mv	a2,s0
    8000163c:	120c                	addi	a1,sp,288
    8000163e:	855a                	mv	a0,s6
    80001640:	c19fe0ef          	jal	80000258 <memcpy>
    mlk_memcpy(out3, tmp3, outlen);
    80001644:	8622                	mv	a2,s0
    80001646:	132c                	addi	a1,sp,424
    80001648:	8526                	mv	a0,s1
    8000164a:	c0ffe0ef          	jal	80000258 <memcpy>
  }

  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  mlk_zeroize(&statex, sizeof(statex));
    8000164e:	854e                	mv	a0,s3
    80001650:	32000593          	li	a1,800
    80001654:	d05fe0ef          	jal	80000358 <mlk_zeroize>
  mlk_zeroize(tmp0, sizeof(tmp0));
    80001658:	0808                	addi	a0,sp,16
    8000165a:	08800593          	li	a1,136
    8000165e:	cfbfe0ef          	jal	80000358 <mlk_zeroize>
  mlk_zeroize(tmp1, sizeof(tmp1));
    80001662:	0928                	addi	a0,sp,152
    80001664:	08800593          	li	a1,136
    80001668:	cf1fe0ef          	jal	80000358 <mlk_zeroize>
  mlk_zeroize(tmp2, sizeof(tmp2));
    8000166c:	1208                	addi	a0,sp,288
    8000166e:	08800593          	li	a1,136
    80001672:	ce7fe0ef          	jal	80000358 <mlk_zeroize>
  mlk_zeroize(tmp3, sizeof(tmp3));
    80001676:	1328                	addi	a0,sp,424
    80001678:	08800593          	li	a1,136
    8000167c:	cddfe0ef          	jal	80000358 <mlk_zeroize>
}
    80001680:	5a813083          	ld	ra,1448(sp)
    80001684:	5a013403          	ld	s0,1440(sp)
    80001688:	59813483          	ld	s1,1432(sp)
    8000168c:	59013903          	ld	s2,1424(sp)
    80001690:	58813983          	ld	s3,1416(sp)
    80001694:	58013a03          	ld	s4,1408(sp)
    80001698:	57813a83          	ld	s5,1400(sp)
    8000169c:	57013b03          	ld	s6,1392(sp)
    800016a0:	56813b83          	ld	s7,1384(sp)
    800016a4:	56013c03          	ld	s8,1376(sp)
    800016a8:	5b010113          	addi	sp,sp,1456
    800016ac:	8082                	ret

00000000800016ae <mlkem_shake128x4_absorb_once>:
{
    800016ae:	7139                	addi	sp,sp,-64
    800016b0:	f426                	sd	s1,40(sp)
    800016b2:	f04a                	sd	s2,32(sp)
    800016b4:	84ae                	mv	s1,a1
    800016b6:	8932                	mv	s2,a2
  mlk_memset(state, 0, sizeof(mlk_shake128x4ctx));
    800016b8:	4581                	li	a1,0
    800016ba:	32000613          	li	a2,800
{
    800016be:	f822                	sd	s0,48(sp)
    800016c0:	fc06                	sd	ra,56(sp)
    800016c2:	842a                	mv	s0,a0
    800016c4:	ec36                	sd	a3,24(sp)
    800016c6:	e83a                	sd	a4,16(sp)
    800016c8:	e43e                	sd	a5,8(sp)
  mlk_memset(state, 0, sizeof(mlk_shake128x4ctx));
    800016ca:	babfe0ef          	jal	80000274 <memset>
  mlk_keccak_absorb_once_x4(state->ctx, SHAKE128_RATE, in0, in1, in2, in3,
    800016ce:	8522                	mv	a0,s0
}
    800016d0:	7442                	ld	s0,48(sp)
  mlk_keccak_absorb_once_x4(state->ctx, SHAKE128_RATE, in0, in1, in2, in3,
    800016d2:	6822                	ld	a6,8(sp)
    800016d4:	67c2                	ld	a5,16(sp)
    800016d6:	6762                	ld	a4,24(sp)
}
    800016d8:	70e2                	ld	ra,56(sp)
  mlk_keccak_absorb_once_x4(state->ctx, SHAKE128_RATE, in0, in1, in2, in3,
    800016da:	86ca                	mv	a3,s2
    800016dc:	8626                	mv	a2,s1
}
    800016de:	7902                	ld	s2,32(sp)
    800016e0:	74a2                	ld	s1,40(sp)
  mlk_keccak_absorb_once_x4(state->ctx, SHAKE128_RATE, in0, in1, in2, in3,
    800016e2:	0a800593          	li	a1,168
}
    800016e6:	6121                	addi	sp,sp,64
  mlk_keccak_absorb_once_x4(state->ctx, SHAKE128_RATE, in0, in1, in2, in3,
    800016e8:	b3e1                	j	800014b0 <mlk_keccak_absorb_once_x4.constprop.0>

00000000800016ea <mlkem_poly_rej_uniform_x4>:
{
    800016ea:	81010113          	addi	sp,sp,-2032
    800016ee:	7e113423          	sd	ra,2024(sp)
    800016f2:	7e813023          	sd	s0,2016(sp)
    800016f6:	7c913c23          	sd	s1,2008(sp)
    800016fa:	7d213823          	sd	s2,2000(sp)
    800016fe:	7d313423          	sd	s3,1992(sp)
    80001702:	7d413023          	sd	s4,1984(sp)
    80001706:	7b513c23          	sd	s5,1976(sp)
    8000170a:	7b613823          	sd	s6,1968(sp)
    8000170e:	7b713423          	sd	s7,1960(sp)
    80001712:	7b813023          	sd	s8,1952(sp)
    80001716:	79913c23          	sd	s9,1944(sp)
    8000171a:	79a13823          	sd	s10,1936(sp)
    8000171e:	79b13423          	sd	s11,1928(sp)
    80001722:	6785                	lui	a5,0x1
    80001724:	c4010113          	addi	sp,sp,-960
    80001728:	8d2e                	mv	s10,a1
    8000172a:	80078793          	addi	a5,a5,-2048 # 800 <_heap_size-0x3800>
    8000172e:	85ba                	mv	a1,a4
    80001730:	0818                	addi	a4,sp,16
    80001732:	00f70433          	add	s0,a4,a5
    80001736:	81f40413          	addi	s0,s0,-2017
    8000173a:	9801                	andi	s0,s0,-32
  mlk_xof_x4_absorb(&statex, seed, MLKEM_SYMBYTES + 2);
    8000173c:	00140493          	addi	s1,s0,1
    80001740:	0c058713          	addi	a4,a1,192
{
    80001744:	8caa                	mv	s9,a0
    80001746:	8db2                	mv	s11,a2
  mlk_xof_x4_absorb(&statex, seed, MLKEM_SYMBYTES + 2);
    80001748:	7ff48513          	addi	a0,s1,2047
    8000174c:	04058613          	addi	a2,a1,64
{
    80001750:	e036                	sd	a3,0(sp)
  mlk_xof_x4_absorb(&statex, seed, MLKEM_SYMBYTES + 2);
    80001752:	02200793          	li	a5,34
    80001756:	08058693          	addi	a3,a1,128
    8000175a:	f55ff0ef          	jal	800016ae <mlkem_shake128x4_absorb_once>
  mlk_xof_x4_squeezeblocks(buf, MLKEM_GEN_MATRIX_NBLOCKS, &statex);
    8000175e:	60040b13          	addi	s6,s0,1536
    80001762:	40040b93          	addi	s7,s0,1024
    80001766:	20040c13          	addi	s8,s0,512
    8000176a:	7ff48793          	addi	a5,s1,2047
    8000176e:	470d                	li	a4,3
    80001770:	86da                	mv	a3,s6
    80001772:	865e                	mv	a2,s7
    80001774:	85e2                	mv	a1,s8
    80001776:	8522                	mv	a0,s0
    80001778:	d33ff0ef          	jal	800014aa <mlkem_shake128x4_squeezeblocks>
  return mlk_rej_uniform_c(r, target, offset, buf, buflen);
    8000177c:	1f800693          	li	a3,504
    80001780:	8622                	mv	a2,s0
    80001782:	4581                	li	a1,0
    80001784:	8566                	mv	a0,s9
    80001786:	d2cff0ef          	jal	80000cb2 <mlk_rej_uniform_c.constprop.0>
    8000178a:	1f800693          	li	a3,504
    8000178e:	8662                	mv	a2,s8
    80001790:	4581                	li	a1,0
    80001792:	8a2a                	mv	s4,a0
    80001794:	856a                	mv	a0,s10
    80001796:	d1cff0ef          	jal	80000cb2 <mlk_rej_uniform_c.constprop.0>
    8000179a:	1f800693          	li	a3,504
    8000179e:	865e                	mv	a2,s7
    800017a0:	4581                	li	a1,0
    800017a2:	89aa                	mv	s3,a0
    800017a4:	856e                	mv	a0,s11
    800017a6:	d0cff0ef          	jal	80000cb2 <mlk_rej_uniform_c.constprop.0>
    800017aa:	892a                	mv	s2,a0
    800017ac:	6502                	ld	a0,0(sp)
    800017ae:	1f800693          	li	a3,504
    800017b2:	865a                	mv	a2,s6
    800017b4:	4581                	li	a1,0
    800017b6:	cfcff0ef          	jal	80000cb2 <mlk_rej_uniform_c.constprop.0>
    800017ba:	00140a93          	addi	s5,s0,1
    800017be:	84aa                	mv	s1,a0
    mlk_xof_x4_squeezeblocks(buf, 1, &statex);
    800017c0:	7ffa8793          	addi	a5,s5,2047
  while (ctr[0] < MLKEM_N || ctr[1] < MLKEM_N || ctr[2] < MLKEM_N ||
    800017c4:	100a3693          	sltiu	a3,s4,256
    800017c8:	1009b713          	sltiu	a4,s3,256
    800017cc:	8f55                	or	a4,a4,a3
    800017ce:	10093693          	sltiu	a3,s2,256
    800017d2:	8f55                	or	a4,a4,a3
    800017d4:	ef29                	bnez	a4,8000182e <mlkem_poly_rej_uniform_x4+0x144>
    800017d6:	1004b713          	sltiu	a4,s1,256
    800017da:	eb31                	bnez	a4,8000182e <mlkem_poly_rej_uniform_x4+0x144>
  mlk_xof_x4_release(&statex);
    800017dc:	7ffa8513          	addi	a0,s5,2047
    800017e0:	903ff0ef          	jal	800010e2 <mlkem_shake128x4_release>
  mlk_zeroize(buf, sizeof(buf));
    800017e4:	6585                	lui	a1,0x1
    800017e6:	8522                	mv	a0,s0
    800017e8:	80058593          	addi	a1,a1,-2048 # 800 <_heap_size-0x3800>
    800017ec:	b6dfe0ef          	jal	80000358 <mlk_zeroize>
}
    800017f0:	3c010113          	addi	sp,sp,960
    800017f4:	7e813083          	ld	ra,2024(sp)
    800017f8:	7e013403          	ld	s0,2016(sp)
    800017fc:	7d813483          	ld	s1,2008(sp)
    80001800:	7d013903          	ld	s2,2000(sp)
    80001804:	7c813983          	ld	s3,1992(sp)
    80001808:	7c013a03          	ld	s4,1984(sp)
    8000180c:	7b813a83          	ld	s5,1976(sp)
    80001810:	7b013b03          	ld	s6,1968(sp)
    80001814:	7a813b83          	ld	s7,1960(sp)
    80001818:	7a013c03          	ld	s8,1952(sp)
    8000181c:	79813c83          	ld	s9,1944(sp)
    80001820:	79013d03          	ld	s10,1936(sp)
    80001824:	78813d83          	ld	s11,1928(sp)
    80001828:	7f010113          	addi	sp,sp,2032
    8000182c:	8082                	ret
    mlk_xof_x4_squeezeblocks(buf, 1, &statex);
    8000182e:	4705                	li	a4,1
    80001830:	86da                	mv	a3,s6
    80001832:	865e                	mv	a2,s7
    80001834:	85e2                	mv	a1,s8
    80001836:	8522                	mv	a0,s0
    80001838:	e43e                	sd	a5,8(sp)
    8000183a:	c71ff0ef          	jal	800014aa <mlkem_shake128x4_squeezeblocks>
  return mlk_rej_uniform_c(r, target, offset, buf, buflen);
    8000183e:	85d2                	mv	a1,s4
    80001840:	0a800693          	li	a3,168
    80001844:	8622                	mv	a2,s0
    80001846:	8566                	mv	a0,s9
    80001848:	c6aff0ef          	jal	80000cb2 <mlk_rej_uniform_c.constprop.0>
    8000184c:	85ce                	mv	a1,s3
    8000184e:	0a800693          	li	a3,168
    80001852:	8662                	mv	a2,s8
    80001854:	8a2a                	mv	s4,a0
    80001856:	856a                	mv	a0,s10
    80001858:	c5aff0ef          	jal	80000cb2 <mlk_rej_uniform_c.constprop.0>
    8000185c:	85ca                	mv	a1,s2
    8000185e:	0a800693          	li	a3,168
    80001862:	865e                	mv	a2,s7
    80001864:	89aa                	mv	s3,a0
    80001866:	856e                	mv	a0,s11
    80001868:	c4aff0ef          	jal	80000cb2 <mlk_rej_uniform_c.constprop.0>
    8000186c:	892a                	mv	s2,a0
    8000186e:	6502                	ld	a0,0(sp)
    80001870:	85a6                	mv	a1,s1
    80001872:	0a800693          	li	a3,168
    80001876:	865a                	mv	a2,s6
    80001878:	c3aff0ef          	jal	80000cb2 <mlk_rej_uniform_c.constprop.0>
    8000187c:	67a2                	ld	a5,8(sp)
    8000187e:	84aa                	mv	s1,a0
    80001880:	b791                	j	800017c4 <mlkem_poly_rej_uniform_x4+0xda>

0000000080001882 <mlkem_gen_matrix>:
 *
 * Not static for benchmarking */
MLK_INTERNAL_API
void mlk_gen_matrix(mlk_polymat *a, const uint8_t seed[MLKEM_SYMBYTES],
                    int transposed)
{
    80001882:	714d                	addi	sp,sp,-336
    80001884:	e2a2                	sd	s0,320(sp)
    80001886:	02f10413          	addi	s0,sp,47
    8000188a:	9801                	andi	s0,s0,-32
    8000188c:	fe26                	sd	s1,312(sp)
    8000188e:	fa4a                	sd	s2,304(sp)
    80001890:	f64e                	sd	s3,296(sp)
    80001892:	f252                	sd	s4,288(sp)
    80001894:	e686                	sd	ra,328(sp)
    80001896:	84aa                	mv	s1,a0
    80001898:	8a32                	mv	s4,a2
    8000189a:	8922                	mv	s2,s0
    8000189c:	10040993          	addi	s3,s0,256
  unsigned i, j;
  MLK_ALIGN uint8_t seed_ext[4][MLK_ALIGN_UP(MLKEM_SYMBYTES + 2)];

  for (j = 0; j < 4; j++)
  {
    mlk_memcpy(seed_ext[j], seed, MLKEM_SYMBYTES);
    800018a0:	854a                	mv	a0,s2
    800018a2:	02000613          	li	a2,32
    800018a6:	e42e                	sd	a1,8(sp)
  for (j = 0; j < 4; j++)
    800018a8:	04090913          	addi	s2,s2,64
    mlk_memcpy(seed_ext[j], seed, MLKEM_SYMBYTES);
    800018ac:	9adfe0ef          	jal	80000258 <memcpy>
  for (j = 0; j < 4; j++)
    800018b0:	65a2                	ld	a1,8(sp)
    800018b2:	ff3917e3          	bne	s2,s3,800018a0 <mlkem_gen_matrix+0x1e>
        seed_ext[j][MLKEM_SYMBYTES + 1] = y;
      }
      else
      {
        seed_ext[j][MLKEM_SYMBYTES + 0] = y;
        seed_ext[j][MLKEM_SYMBYTES + 1] = x;
    800018b6:	02041023          	sh	zero,32(s0)
      if (transposed)
    800018ba:	040a0763          	beqz	s4,80001908 <mlkem_gen_matrix+0x86>
        seed_ext[j][MLKEM_SYMBYTES + 0] = x;
    800018be:	4781                	li	a5,0
        seed_ext[j][MLKEM_SYMBYTES + 1] = y;
    800018c0:	4705                	li	a4,1
    800018c2:	06f40023          	sb	a5,96(s0)
    800018c6:	06e400a3          	sb	a4,97(s0)
        seed_ext[j][MLKEM_SYMBYTES + 1] = x;
    800018ca:	0ae40023          	sb	a4,160(s0)
    800018ce:	0af400a3          	sb	a5,161(s0)
      }
    }

    mlk_poly_rej_uniform_x4(&a->vec[i / MLKEM_K].vec[i % MLKEM_K],
    800018d2:	8722                	mv	a4,s0
    800018d4:	10100793          	li	a5,257
    800018d8:	60048693          	addi	a3,s1,1536
    800018dc:	40048613          	addi	a2,s1,1024
    800018e0:	20048593          	addi	a1,s1,512
    800018e4:	8526                	mv	a0,s1
    800018e6:	0ef41023          	sh	a5,224(s0)
    800018ea:	e01ff0ef          	jal	800016ea <mlkem_poly_rej_uniform_x4>
   */
  mlk_polymat_permute_bitrev_to_custom(a);

  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  mlk_zeroize(seed_ext, sizeof(seed_ext));
    800018ee:	8522                	mv	a0,s0
    800018f0:	10000593          	li	a1,256
    800018f4:	a65fe0ef          	jal	80000358 <mlk_zeroize>
}
    800018f8:	60b6                	ld	ra,328(sp)
    800018fa:	6416                	ld	s0,320(sp)
    800018fc:	74f2                	ld	s1,312(sp)
    800018fe:	7952                	ld	s2,304(sp)
    80001900:	79b2                	ld	s3,296(sp)
    80001902:	7a12                	ld	s4,288(sp)
    80001904:	6171                	addi	sp,sp,336
    80001906:	8082                	ret
        seed_ext[j][MLKEM_SYMBYTES + 0] = y;
    80001908:	4785                	li	a5,1
        seed_ext[j][MLKEM_SYMBYTES + 1] = x;
    8000190a:	4701                	li	a4,0
    8000190c:	bf5d                	j	800018c2 <mlkem_gen_matrix+0x40>

000000008000190e <mlkem_indcpa_enc.isra.0>:
 *              uses x4-batched Keccak-f1600 (see `mlk_gen_matrix()` above).
 *            - We use a mulcache to speed up matrix-vector multiplication.
 *            - We include buffer zeroization.
 */
MLK_INTERNAL_API
int mlk_indcpa_enc(uint8_t c[MLKEM_INDCPA_BYTES],
    8000190e:	7131                	addi	sp,sp,-192
    80001910:	72f9                	lui	t0,0xffffe
    80001912:	fd06                	sd	ra,184(sp)
    80001914:	f922                	sd	s0,176(sp)
    80001916:	f526                	sd	s1,168(sp)
    80001918:	f14a                	sd	s2,160(sp)
    8000191a:	ed4e                	sd	s3,152(sp)
    8000191c:	e952                	sd	s4,144(sp)
    8000191e:	e15a                	sd	s6,128(sp)
    80001920:	f0ea                	sd	s10,96(sp)
    80001922:	e556                	sd	s5,136(sp)
    80001924:	fcde                	sd	s7,120(sp)
    80001926:	f8e2                	sd	s8,112(sp)
    80001928:	f4e6                	sd	s9,104(sp)
    8000192a:	ecee                	sd	s11,88(sp)
    8000192c:	9116                	add	sp,sp,t0
    8000192e:	03f10413          	addi	s0,sp,63
    80001932:	9801                	andi	s0,s0,-32
    80001934:	8a2a                	mv	s4,a0
  mlk_polyvec_frombytes(pk, packedpk);
    80001936:	6505                	lui	a0,0x1
    80001938:	9522                	add	a0,a0,s0
int mlk_indcpa_enc(uint8_t c[MLKEM_INDCPA_BYTES],
    8000193a:	84ae                	mv	s1,a1
  mlk_memcpy(seed, packedpk + MLKEM_POLYVECBYTES, MLKEM_SYMBYTES);
    8000193c:	6b09                	lui	s6,0x2
  mlk_polyvec_frombytes(pk, packedpk);
    8000193e:	85b2                	mv	a1,a2
int mlk_indcpa_enc(uint8_t c[MLKEM_INDCPA_BYTES],
    80001940:	8932                	mv	s2,a2
    80001942:	8d36                	mv	s10,a3
  mlk_memcpy(seed, packedpk + MLKEM_POLYVECBYTES, MLKEM_SYMBYTES);
    80001944:	9b22                	add	s6,s6,s0
  mlk_polyvec_frombytes(pk, packedpk);
    80001946:	a8dfe0ef          	jal	800003d2 <mlkem_polyvec_frombytes>
  mlk_memcpy(seed, packedpk + MLKEM_POLYVECBYTES, MLKEM_SYMBYTES);
    8000194a:	02000613          	li	a2,32
    8000194e:	30090593          	addi	a1,s2,768
    80001952:	855a                	mv	a0,s6
    80001954:	905fe0ef          	jal	80000258 <memcpy>
    80001958:	4981                	li	s3,0
__contract__(ensures(return_value == 0)) { return mlk_ct_opt_blocker_u64; }
    8000195a:	81018613          	addi	a2,gp,-2032 # 800034f0 <mlkem_ct_opt_blocker_u64>
    {
      /* mlk_ct_sel_int16(MLKEM_Q_HALF, 0, b) is `Decompress_1(b != 0)`
       * as per @[FIPS203, Eq (4.8)]. */

      /* Prevent the compiler from recognizing this as a bit selection */
      uint8_t mask = mlk_value_barrier_u8((uint8_t)(1u << j));
    8000195e:	4805                	li	a6,1
    for (j = 0; j < 8; j++)
    80001960:	48a1                	li	a7,8
  for (i = 0; i < MLKEM_N / 8; i++)
    80001962:	02000313          	li	t1,32
    for (j = 0; j < 8; j++)
    80001966:	0039951b          	slliw	a0,s3,0x3
    8000196a:	4701                	li	a4,0
      r->coeffs[8 * i + j] = mlk_ct_sel_int16(MLKEM_Q_HALF, 0, msg[i] & mask);
    8000196c:	013485b3          	add	a1,s1,s3
    80001970:	00063e83          	ld	t4,0(a2)
      uint8_t mask = mlk_value_barrier_u8((uint8_t)(1u << j));
    80001974:	00e817bb          	sllw	a5,a6,a4
    80001978:	00063e03          	ld	t3,0(a2)
__contract__(ensures(return_value == b)) { return (b ^ mlk_ct_get_optblocker_u8()); }
    8000197c:	01d7c7b3          	xor	a5,a5,t4
      r->coeffs[8 * i + j] = mlk_ct_sel_int16(MLKEM_Q_HALF, 0, msg[i] & mask);
    80001980:	0005ce83          	lbu	t4,0(a1)
    80001984:	00a706bb          	addw	a3,a4,a0
    80001988:	0686                	slli	a3,a3,0x1
  int32_t tmp = mlk_value_barrier_i32(-((int32_t)x));
    8000198a:	01d7f7b3          	and	a5,a5,t4
    8000198e:	40f007bb          	negw	a5,a5
__contract__(ensures(return_value == b)) { return (b ^ mlk_ct_get_optblocker_i32()); }
    80001992:	01c7c7b3          	xor	a5,a5,t3
  tmp >>= 16;
    80001996:	4107d79b          	sraiw	a5,a5,0x10
    8000199a:	96da                	add	a3,a3,s6
    8000199c:	6817f793          	andi	a5,a5,1665
    800019a0:	c0f69023          	sh	a5,-1024(a3)
    for (j = 0; j < 8; j++)
    800019a4:	2705                	addiw	a4,a4,1
    800019a6:	fd1715e3          	bne	a4,a7,80001970 <mlkem_indcpa_enc.isra.0+0x62>
  for (i = 0; i < MLKEM_N / 8; i++)
    800019aa:	0985                	addi	s3,s3,1
    800019ac:	fa699de3          	bne	s3,t1,80001966 <mlkem_indcpa_enc.isra.0+0x58>
#error mlk_poly_getnoise_eta1122_4x assumes MLKEM_ETA1 > MLKEM_ETA2
#endif
  MLK_ALIGN uint8_t buf[4][MLK_ALIGN_UP(MLKEM_ETA1 * MLKEM_N / 4)];
  MLK_ALIGN uint8_t extkey[4][MLK_ALIGN_UP(MLKEM_SYMBYTES + 1)];

  mlk_memcpy(extkey[0], seed, MLKEM_SYMBYTES);
    800019b0:	6489                	lui	s1,0x2
   * This is needed because in re-encryption the publicseed originated from sk
   * which is marked undefined.
   */
  MLK_CT_TESTING_DECLASSIFY(seed, MLKEM_SYMBYTES);

  mlk_gen_matrix(at, seed, 1 /* transpose */);
    800019b2:	85da                	mv	a1,s6
    800019b4:	4605                	li	a2,1
    800019b6:	8522                	mv	a0,s0
    800019b8:	80048493          	addi	s1,s1,-2048 # 1800 <_heap_size-0x2800>
    800019bc:	94a2                	add	s1,s1,s0
    800019be:	ec5ff0ef          	jal	80001882 <mlkem_gen_matrix>
    800019c2:	864e                	mv	a2,s3
    800019c4:	85ea                	mv	a1,s10
    800019c6:	8526                	mv	a0,s1
    800019c8:	891fe0ef          	jal	80000258 <memcpy>
  mlk_memcpy(extkey[1], seed, MLKEM_SYMBYTES);
    800019cc:	864e                	mv	a2,s3
    800019ce:	85ea                	mv	a1,s10
    800019d0:	04048513          	addi	a0,s1,64
    800019d4:	885fe0ef          	jal	80000258 <memcpy>
  mlk_memcpy(extkey[2], seed, MLKEM_SYMBYTES);
    800019d8:	864e                	mv	a2,s3
    800019da:	85ea                	mv	a1,s10
    800019dc:	08048513          	addi	a0,s1,128
    800019e0:	879fe0ef          	jal	80000258 <memcpy>
  mlk_memcpy(extkey[3], seed, MLKEM_SYMBYTES);
    800019e4:	864e                	mv	a2,s3
    800019e6:	85ea                	mv	a1,s10
    800019e8:	0c048513          	addi	a0,s1,192
    800019ec:	86dfe0ef          	jal	80000258 <memcpy>
  extkey[0][MLKEM_SYMBYTES] = nonce0;
  extkey[1][MLKEM_SYMBYTES] = nonce1;
    800019f0:	4b85                	li	s7,1
  extkey[2][MLKEM_SYMBYTES] = nonce2;
    800019f2:	4789                	li	a5,2
   * than necessary. */
#if !defined(FIPS202_X4_DEFAULT_IMPLEMENTATION) && \
    !defined(MLK_CONFIG_SERIAL_FIPS202_ONLY)
  mlk_prf_eta1_x4(buf, extkey);
#else
  mlk_prf_eta1(buf[0], extkey[0]);
    800019f4:	01740933          	add	s2,s0,s7
    800019f8:	7ff90913          	addi	s2,s2,2047
  extkey[2][MLKEM_SYMBYTES] = nonce2;
    800019fc:	8afb0023          	sb	a5,-1888(s6) # 18a0 <_heap_size-0x2760>
  extkey[3][MLKEM_SYMBYTES] = nonce3;
    80001a00:	478d                	li	a5,3
    80001a02:	8efb0023          	sb	a5,-1824(s6)
  mlk_prf_eta1(buf[0], extkey[0]);
    80001a06:	8626                	mv	a2,s1
    80001a08:	854a                	mv	a0,s2
  extkey[0][MLKEM_SYMBYTES] = nonce0;
    80001a0a:	820b0023          	sb	zero,-2016(s6)
  extkey[1][MLKEM_SYMBYTES] = nonce1;
    80001a0e:	877b0023          	sb	s7,-1952(s6)
  mlk_prf_eta1(buf[0], extkey[0]);
    80001a12:	02100693          	li	a3,33
    80001a16:	0c000593          	li	a1,192
    80001a1a:	905ff0ef          	jal	8000131e <mlkem_shake256>
  mlk_prf_eta1(buf[1], extkey[1]);
    80001a1e:	04048613          	addi	a2,s1,64
    80001a22:	0c090513          	addi	a0,s2,192
    80001a26:	02100693          	li	a3,33
    80001a2a:	0c000593          	li	a1,192
    80001a2e:	8f1ff0ef          	jal	8000131e <mlkem_shake256>
  mlk_prf_eta2(buf[2], extkey[2]);
    80001a32:	08048613          	addi	a2,s1,128
    80001a36:	18090513          	addi	a0,s2,384
    80001a3a:	02100693          	li	a3,33
    80001a3e:	08000593          	li	a1,128
    80001a42:	8ddff0ef          	jal	8000131e <mlkem_shake256>
  mlk_poly_cbd3(r, buf);
    80001a46:	6a85                	lui	s5,0x1
  mlk_prf_eta2(buf[3], extkey[3]);
    80001a48:	02100693          	li	a3,33
    80001a4c:	0c048613          	addi	a2,s1,192
    80001a50:	24090513          	addi	a0,s2,576
    80001a54:	08000593          	li	a1,128
  mlk_poly_cbd3(r, buf);
    80001a58:	400a8a93          	addi	s5,s5,1024 # 1400 <_heap_size-0x2c00>
  mlk_prf_eta2(buf[3], extkey[3]);
    80001a5c:	8c3ff0ef          	jal	8000131e <mlkem_shake256>
  mlk_poly_cbd3(r, buf);
    80001a60:	9aa2                	add	s5,s5,s0
    80001a62:	85ca                	mv	a1,s2
    80001a64:	8556                	mv	a0,s5
    80001a66:	abbfe0ef          	jal	80000520 <mlkem_poly_cbd3>
    80001a6a:	0c090593          	addi	a1,s2,192
    80001a6e:	200a8513          	addi	a0,s5,512
  mlk_poly_cbd2(r, buf);
    80001a72:	40140c93          	addi	s9,s0,1025
  mlk_poly_cbd3(r, buf);
    80001a76:	aabfe0ef          	jal	80000520 <mlkem_poly_cbd3>
  mlk_poly_cbd2(r, buf);
    80001a7a:	7ffc8c93          	addi	s9,s9,2047
    80001a7e:	18090593          	addi	a1,s2,384
    80001a82:	8566                	mv	a0,s9
    80001a84:	a49fe0ef          	jal	800004cc <mlkem_poly_cbd2>
    80001a88:	24090593          	addi	a1,s2,576
    80001a8c:	200c8513          	addi	a0,s9,512
    80001a90:	a3dfe0ef          	jal	800004cc <mlkem_poly_cbd2>
  mlk_assert_abs_bound(r2, MLKEM_N, MLKEM_ETA2 + 1);
  mlk_assert_abs_bound(r3, MLKEM_N, MLKEM_ETA2 + 1);

  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  mlk_zeroize(buf, sizeof(buf));
    80001a94:	854a                	mv	a0,s2
    80001a96:	30000593          	li	a1,768
    80001a9a:	8bffe0ef          	jal	80000358 <mlk_zeroize>
  mlk_zeroize(extkey, sizeof(extkey));
    80001a9e:	8526                	mv	a0,s1
    80001aa0:	10000593          	li	a1,256
    80001aa4:	8b5fe0ef          	jal	80000358 <mlk_zeroize>
  mlk_memcpy(extkey, seed, MLKEM_SYMBYTES);
    80001aa8:	864e                	mv	a2,s3
    80001aaa:	85ea                	mv	a1,s10
    80001aac:	8526                	mv	a0,s1
    80001aae:	faafe0ef          	jal	80000258 <memcpy>
  extkey[MLKEM_SYMBYTES] = nonce;
    80001ab2:	4c11                	li	s8,4
  mlk_prf_eta2(buf, extkey);
    80001ab4:	8626                	mv	a2,s1
    80001ab6:	02100693          	li	a3,33
    80001aba:	854a                	mv	a0,s2
  extkey[MLKEM_SYMBYTES] = nonce;
    80001abc:	838b0023          	sb	s8,-2016(s6)
  mlk_prf_eta2(buf, extkey);
    80001ac0:	08000593          	li	a1,128
    80001ac4:	85bff0ef          	jal	8000131e <mlkem_shake256>
  mlk_poly_cbd2(r, buf);
    80001ac8:	6789                	lui	a5,0x2
    80001aca:	a0078793          	addi	a5,a5,-1536 # 1a00 <_heap_size-0x2600>
    80001ace:	97a2                	add	a5,a5,s0
    80001ad0:	853e                	mv	a0,a5
    80001ad2:	85ca                	mv	a1,s2
    80001ad4:	e43e                	sd	a5,8(sp)
    80001ad6:	9f7fe0ef          	jal	800004cc <mlkem_poly_cbd2>
  mlk_zeroize(buf, sizeof(buf));
    80001ada:	854a                	mv	a0,s2
    80001adc:	08000593          	li	a1,128
    80001ae0:	879fe0ef          	jal	80000358 <mlk_zeroize>
  mlk_zeroize(extkey, sizeof(extkey));
    80001ae4:	02100593          	li	a1,33
    80001ae8:	8526                	mv	a0,s1
    80001aea:	86ffe0ef          	jal	80000358 <mlk_zeroize>

  mlk_enc_getnoise_eta1_eta2(sp, ep, epp, coins);

  mlk_polyvec_ntt(sp);
    80001aee:	8556                	mv	a0,s5
    80001af0:	ab8ff0ef          	jal	80000da8 <mlkem_polyvec_ntt>

  mlk_polyvec_mulcache_compute(sp_cache, sp);
    80001af4:	8526                	mv	a0,s1
    80001af6:	85d6                	mv	a1,s5
    80001af8:	c9aff0ef          	jal	80000f92 <mlkem_polyvec_mulcache_compute>
  mlk_polyvec_basemul_acc_montgomery_cached_c(r, a, b, b_cache);
    80001afc:	86a6                	mv	a3,s1
    80001afe:	854a                	mv	a0,s2
    80001b00:	8656                	mv	a2,s5
    80001b02:	85a2                	mv	a1,s0
    80001b04:	917fe0ef          	jal	8000041a <mlk_polyvec_basemul_acc_montgomery_cached_c>
    80001b08:	86a6                	mv	a3,s1
    80001b0a:	20090513          	addi	a0,s2,512
    80001b0e:	8656                	mv	a2,s5
    80001b10:	40040593          	addi	a1,s0,1024
    80001b14:	6b05                	lui	s6,0x1
    80001b16:	6989                	lui	s3,0x2
    80001b18:	903fe0ef          	jal	8000041a <mlk_polyvec_basemul_acc_montgomery_cached_c>
    80001b1c:	e0098993          	addi	s3,s3,-512 # 1e00 <_heap_size-0x2200>
    80001b20:	9b22                	add	s6,s6,s0
    80001b22:	86a6                	mv	a3,s1
    80001b24:	8656                	mv	a2,s5
    80001b26:	85da                	mv	a1,s6
    80001b28:	01340533          	add	a0,s0,s3
    80001b2c:	8effe0ef          	jal	8000041a <mlk_polyvec_basemul_acc_montgomery_cached_c>
    mlk_assert_abs_bound(r, MLKEM_N, MLK_INVNTT_BOUND);
    return;
  }
#endif /* MLK_USE_NATIVE_INTT */

  mlk_poly_invntt_tomont_c(r);
    80001b30:	854a                	mv	a0,s2
    80001b32:	b36ff0ef          	jal	80000e68 <mlk_poly_invntt_tomont_c>
    80001b36:	20090513          	addi	a0,s2,512
    80001b3a:	b2eff0ef          	jal	80000e68 <mlk_poly_invntt_tomont_c>
    80001b3e:	01340533          	add	a0,s0,s3
    80001b42:	b26ff0ef          	jal	80000e68 <mlk_poly_invntt_tomont_c>
    mlk_poly_add(&r->vec[i], &b->vec[i]);
    80001b46:	854a                	mv	a0,s2
    80001b48:	85e6                	mv	a1,s9
    80001b4a:	81ffe0ef          	jal	80000368 <mlkem_poly_add>
    80001b4e:	20090513          	addi	a0,s2,512
    80001b52:	200c8593          	addi	a1,s9,512
    80001b56:	813fe0ef          	jal	80000368 <mlkem_poly_add>

  mlk_polyvec_invntt_tomont(b);
  mlk_poly_invntt_tomont(v);

  mlk_polyvec_add(b, ep);
  mlk_poly_add(v, epp);
    80001b5a:	65a2                	ld	a1,8(sp)
    80001b5c:	01340533          	add	a0,s0,s3
    80001b60:	40140493          	addi	s1,s0,1025
    80001b64:	805fe0ef          	jal	80000368 <mlkem_poly_add>
  mlk_poly_add(v, k);
    80001b68:	6589                	lui	a1,0x2
    80001b6a:	c0058593          	addi	a1,a1,-1024 # 1c00 <_heap_size-0x2400>
    80001b6e:	95a2                	add	a1,a1,s0
    80001b70:	01340533          	add	a0,s0,s3
    80001b74:	ff4fe0ef          	jal	80000368 <mlkem_poly_add>

  mlk_polyvec_reduce(b);
    80001b78:	854a                	mv	a0,s2
    80001b7a:	a18ff0ef          	jal	80000d92 <mlkem_polyvec_reduce>
  mlk_poly_reduce_c(r);
    80001b7e:	01340533          	add	a0,s0,s3
    80001b82:	9a8ff0ef          	jal	80000d2a <mlk_poly_reduce_c>
   *   = round(u * 1024 * (2^33 / MLKEM_Q) / 2^33)
   *  ~= round(u * 1024 * round(2^33 / MLKEM_Q) / 2^33)
   * ```
   */
  /* check-magic: 2642263040 == 2^10 * round(2^33 / MLKEM_Q) */
  uint64_t d0 = (uint64_t)u * 2642263040;
    80001b86:	275f7637          	lui	a2,0x275f7
    80001b8a:	060a                	slli	a2,a2,0x2
    80001b8c:	88d2                	mv	a7,s4
  for (i = 0; i < MLKEM_K; i++)
    80001b8e:	4801                	li	a6,0
    80001b90:	01740933          	add	s2,s0,s7
    80001b94:	c0060613          	addi	a2,a2,-1024 # 275f6c00 <_stack_size+0x275e6c00>
  d0 = (d0 + ((uint64_t)1u << 32)) >> 33; /* round(d0/2^33) */
    80001b98:	020b9e93          	slli	t4,s7,0x20
  for (j = 0; j < MLKEM_N / 4; j++)
    80001b9c:	10000f13          	li	t5,256
    for (k = 0; k < 4; k++)
    80001ba0:	8746                	mv	a4,a7
    80001ba2:	4501                	li	a0,0
      t[k] = mlk_scalar_compress_d10(a->coeffs[4 * j + k]);
    80001ba4:	00881f93          	slli	t6,a6,0x8
    for (k = 0; k < 4; k++)
    80001ba8:	01810e13          	addi	t3,sp,24
    80001bac:	4581                	li	a1,0
      t[k] = mlk_scalar_compress_d10(a->coeffs[4 * j + k]);
    80001bae:	00a587bb          	addw	a5,a1,a0
    80001bb2:	97fe                	add	a5,a5,t6
    80001bb4:	0786                	slli	a5,a5,0x1
    80001bb6:	97da                	add	a5,a5,s6
  uint64_t d0 = (uint64_t)u * 2642263040;
    80001bb8:	80079783          	lh	a5,-2048(a5)
    for (k = 0; k < 4; k++)
    80001bbc:	2585                	addiw	a1,a1,1
    80001bbe:	0e09                	addi	t3,t3,2
    80001bc0:	02c787b3          	mul	a5,a5,a2
  d0 = (d0 + ((uint64_t)1u << 32)) >> 33; /* round(d0/2^33) */
    80001bc4:	97f6                	add	a5,a5,t4
    80001bc6:	9385                	srli	a5,a5,0x21
  return (d0 & 0x3FF);
    80001bc8:	3ff7f793          	andi	a5,a5,1023
      t[k] = mlk_scalar_compress_d10(a->coeffs[4 * j + k]);
    80001bcc:	fefe1f23          	sh	a5,-2(t3)
    for (k = 0; k < 4; k++)
    80001bd0:	fd859fe3          	bne	a1,s8,80001bae <mlkem_indcpa_enc.isra.0+0x2a0>
    r[5 * j + 0] = (uint8_t)((t[0] >> 0) & 0xFF);
    80001bd4:	01815783          	lhu	a5,24(sp)
  for (j = 0; j < MLKEM_N / 4; j++)
    80001bd8:	2511                	addiw	a0,a0,4 # 1004 <_heap_size-0x2ffc>
    80001bda:	0715                	addi	a4,a4,5
    r[5 * j + 0] = (uint8_t)((t[0] >> 0) & 0xFF);
    80001bdc:	fef70da3          	sb	a5,-5(a4)
    r[5 * j + 1] = (uint8_t)((t[0] >> 8) | ((t[1] << 2) & 0xFF));
    80001be0:	01a15583          	lhu	a1,26(sp)
    80001be4:	0087d79b          	srliw	a5,a5,0x8
    80001be8:	00259e1b          	slliw	t3,a1,0x2
    80001bec:	01c7e7b3          	or	a5,a5,t3
    80001bf0:	fef70e23          	sb	a5,-4(a4)
    r[5 * j + 2] = (uint8_t)((t[1] >> 6) | ((t[2] << 4) & 0xFF));
    80001bf4:	01c15783          	lhu	a5,28(sp)
    80001bf8:	0065d59b          	srliw	a1,a1,0x6
    80001bfc:	00479e1b          	slliw	t3,a5,0x4
    80001c00:	01c5e5b3          	or	a1,a1,t3
    80001c04:	feb70ea3          	sb	a1,-3(a4)
    r[5 * j + 3] = (uint8_t)((t[2] >> 4) | ((t[3] << 6) & 0xFF));
    80001c08:	01e15583          	lhu	a1,30(sp)
    80001c0c:	0047d79b          	srliw	a5,a5,0x4
    80001c10:	00659e1b          	slliw	t3,a1,0x6
    80001c14:	01c7e7b3          	or	a5,a5,t3
    r[5 * j + 4] = (uint8_t)(t[3] >> 2);
    80001c18:	0025d59b          	srliw	a1,a1,0x2
    r[5 * j + 3] = (uint8_t)((t[2] >> 4) | ((t[3] << 6) & 0xFF));
    80001c1c:	fef70f23          	sb	a5,-2(a4)
    r[5 * j + 4] = (uint8_t)(t[3] >> 2);
    80001c20:	feb70fa3          	sb	a1,-1(a4)
  for (j = 0; j < MLKEM_N / 4; j++)
    80001c24:	f9e512e3          	bne	a0,t5,80001ba8 <mlkem_indcpa_enc.isra.0+0x29a>
    80001c28:	14088893          	addi	a7,a7,320
    80001c2c:	15781963          	bne	a6,s7,80001d7e <mlkem_indcpa_enc.isra.0+0x470>
      t[j] = mlk_scalar_compress_d4(a->coeffs[8 * i + j]);
    80001c30:	6989                	lui	s3,0x2
  uint32_t d0 = (uint32_t)u * 1290160;
    80001c32:	0013b5b7          	lui	a1,0x13b
    80001c36:	280a0a13          	addi	s4,s4,640
    80001c3a:	4601                	li	a2,0
    uint8_t t[8] = {0};
    80001c3c:	089c                	addi	a5,sp,80
      t[j] = mlk_scalar_compress_d4(a->coeffs[8 * i + j]);
    80001c3e:	0834                	addi	a3,sp,24
    80001c40:	99a2                	add	s3,s3,s0
    80001c42:	fb05859b          	addiw	a1,a1,-80 # 13afb0 <_stack_size+0x12afb0>
  return (uint8_t)((d0 + ((uint32_t)1u << 27)) >> 28); /* round(d0/2^28) */
    80001c46:	08000837          	lui	a6,0x8000
    for (j = 0; j < 8; j++)
    80001c4a:	48a1                	li	a7,8
  for (i = 0; i < MLKEM_N / 8; i++)
    80001c4c:	10000513          	li	a0,256
    uint8_t t[8] = {0};
    80001c50:	fc07b423          	sd	zero,-56(a5)
    80001c54:	4301                	li	t1,0
      t[j] = mlk_scalar_compress_d4(a->coeffs[8 * i + j]);
    80001c56:	00c3073b          	addw	a4,t1,a2
    80001c5a:	0706                	slli	a4,a4,0x1
    80001c5c:	974e                	add	a4,a4,s3
  uint32_t d0 = (uint32_t)u * 1290160;
    80001c5e:	e0071703          	lh	a4,-512(a4)
    80001c62:	00668e33          	add	t3,a3,t1
    for (j = 0; j < 8; j++)
    80001c66:	0305                	addi	t1,t1,1
    80001c68:	02b7073b          	mulw	a4,a4,a1
  return (uint8_t)((d0 + ((uint32_t)1u << 27)) >> 28); /* round(d0/2^28) */
    80001c6c:	00e8073b          	addw	a4,a6,a4
    80001c70:	01c7571b          	srliw	a4,a4,0x1c
    80001c74:	00ee0023          	sb	a4,0(t3)
    80001c78:	fd131fe3          	bne	t1,a7,80001c56 <mlkem_indcpa_enc.isra.0+0x348>
    r[i * 4] = (uint8_t)(t[0] | (t[1] << 4));
    80001c7c:	fc97c703          	lbu	a4,-55(a5)
    80001c80:	fc87c303          	lbu	t1,-56(a5)
  for (i = 0; i < MLKEM_N / 8; i++)
    80001c84:	2621                	addiw	a2,a2,8
    r[i * 4] = (uint8_t)(t[0] | (t[1] << 4));
    80001c86:	0047171b          	slliw	a4,a4,0x4
    80001c8a:	00676733          	or	a4,a4,t1
    80001c8e:	00ea0023          	sb	a4,0(s4)
    r[i * 4 + 1] = (uint8_t)(t[2] | (t[3] << 4));
    80001c92:	fcb7c703          	lbu	a4,-53(a5)
    80001c96:	fca7c303          	lbu	t1,-54(a5)
  for (i = 0; i < MLKEM_N / 8; i++)
    80001c9a:	0a11                	addi	s4,s4,4
    r[i * 4 + 1] = (uint8_t)(t[2] | (t[3] << 4));
    80001c9c:	0047171b          	slliw	a4,a4,0x4
    80001ca0:	00676733          	or	a4,a4,t1
    80001ca4:	feea0ea3          	sb	a4,-3(s4)
    r[i * 4 + 2] = (uint8_t)(t[4] | (t[5] << 4));
    80001ca8:	fcd7c703          	lbu	a4,-51(a5)
    80001cac:	fcc7c303          	lbu	t1,-52(a5)
    80001cb0:	0047171b          	slliw	a4,a4,0x4
    80001cb4:	00676733          	or	a4,a4,t1
    80001cb8:	feea0f23          	sb	a4,-2(s4)
    r[i * 4 + 3] = (uint8_t)(t[6] | (t[7] << 4));
    80001cbc:	fcf7c703          	lbu	a4,-49(a5)
    80001cc0:	fce7c303          	lbu	t1,-50(a5)
    80001cc4:	0047171b          	slliw	a4,a4,0x4
    80001cc8:	00676733          	or	a4,a4,t1
    80001ccc:	feea0fa3          	sb	a4,-1(s4)
  for (i = 0; i < MLKEM_N / 8; i++)
    80001cd0:	f8a610e3          	bne	a2,a0,80001c50 <mlkem_indcpa_enc.isra.0+0x342>
  mlk_pack_ciphertext(c, b, v);

cleanup:
  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  MLK_FREE(sp_cache, mlk_polyvec_mulcache, 1, context);
    80001cd4:	6509                	lui	a0,0x2
    80001cd6:	80050513          	addi	a0,a0,-2048 # 1800 <_heap_size-0x2800>
    80001cda:	9522                	add	a0,a0,s0
    80001cdc:	20000593          	li	a1,512
    80001ce0:	e78fe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(epp, mlk_poly, 1, context);
    80001ce4:	6509                	lui	a0,0x2
    80001ce6:	a0050513          	addi	a0,a0,-1536 # 1a00 <_heap_size-0x2600>
    80001cea:	9522                	add	a0,a0,s0
    80001cec:	20000593          	li	a1,512
    80001cf0:	e68fe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(k, mlk_poly, 1, context);
    80001cf4:	6509                	lui	a0,0x2
    80001cf6:	c0050513          	addi	a0,a0,-1024 # 1c00 <_heap_size-0x2400>
    80001cfa:	9522                	add	a0,a0,s0
    80001cfc:	20000593          	li	a1,512
    80001d00:	e58fe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(v, mlk_poly, 1, context);
    80001d04:	6509                	lui	a0,0x2
    80001d06:	e0050513          	addi	a0,a0,-512 # 1e00 <_heap_size-0x2200>
    80001d0a:	9522                	add	a0,a0,s0
    80001d0c:	20000593          	li	a1,512
    80001d10:	e48fe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(b, mlk_polyvec, 1, context);
    80001d14:	7ff90513          	addi	a0,s2,2047
    80001d18:	40000593          	li	a1,1024
    80001d1c:	e3cfe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(ep, mlk_polyvec, 1, context);
    80001d20:	7ff48513          	addi	a0,s1,2047
    80001d24:	40000593          	li	a1,1024
    80001d28:	e30fe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(pkpv, mlk_polyvec, 1, context);
    80001d2c:	6485                	lui	s1,0x1
    80001d2e:	00940533          	add	a0,s0,s1
    80001d32:	40000593          	li	a1,1024
    80001d36:	e22fe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(sp, mlk_polyvec, 1, context);
    80001d3a:	40000593          	li	a1,1024
    80001d3e:	00b48533          	add	a0,s1,a1
    80001d42:	9522                	add	a0,a0,s0
    80001d44:	e14fe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(at, mlk_polymat, 1, context);
    80001d48:	80048593          	addi	a1,s1,-2048 # 800 <_heap_size-0x3800>
    80001d4c:	8522                	mv	a0,s0
    80001d4e:	e0afe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(seed, uint8_t, MLKEM_SYMBYTES, context);
    80001d52:	854e                	mv	a0,s3
    80001d54:	02000593          	li	a1,32
    80001d58:	e00fe0ef          	jal	80000358 <mlk_zeroize>
  return ret;
}
    80001d5c:	6289                	lui	t0,0x2
    80001d5e:	9116                	add	sp,sp,t0
    80001d60:	70ea                	ld	ra,184(sp)
    80001d62:	744a                	ld	s0,176(sp)
    80001d64:	74aa                	ld	s1,168(sp)
    80001d66:	790a                	ld	s2,160(sp)
    80001d68:	69ea                	ld	s3,152(sp)
    80001d6a:	6a4a                	ld	s4,144(sp)
    80001d6c:	6aaa                	ld	s5,136(sp)
    80001d6e:	6b0a                	ld	s6,128(sp)
    80001d70:	7be6                	ld	s7,120(sp)
    80001d72:	7c46                	ld	s8,112(sp)
    80001d74:	7ca6                	ld	s9,104(sp)
    80001d76:	7d06                	ld	s10,96(sp)
    80001d78:	6de6                	ld	s11,88(sp)
    80001d7a:	6129                	addi	sp,sp,192
    80001d7c:	8082                	ret
    80001d7e:	4805                	li	a6,1
    80001d80:	b505                	j	80001ba0 <mlkem_indcpa_enc.isra.0+0x292>

0000000080001d82 <mlkem_dec>:
MLK_EXTERNAL_API
int mlk_kem_dec(uint8_t ss[MLKEM_SSBYTES],
                const uint8_t ct[MLKEM_INDCCA_CIPHERTEXTBYTES],
                const uint8_t sk[MLKEM_INDCCA_SECRETKEYBYTES],
                MLK_CONFIG_CONTEXT_PARAMETER_TYPE context)
{
    80001d82:	81010113          	addi	sp,sp,-2032
    80001d86:	7e813023          	sd	s0,2016(sp)
    80001d8a:	7d213823          	sd	s2,2000(sp)
    80001d8e:	7d313423          	sd	s3,1992(sp)
    80001d92:	7d413023          	sd	s4,1984(sp)
    80001d96:	79a13823          	sd	s10,1936(sp)
    80001d9a:	7e113423          	sd	ra,2024(sp)
    80001d9e:	7c913c23          	sd	s1,2008(sp)
    80001da2:	7b513c23          	sd	s5,1976(sp)
    80001da6:	7b613823          	sd	s6,1968(sp)
    80001daa:	7b713423          	sd	s7,1960(sp)
    80001dae:	7b813023          	sd	s8,1952(sp)
    80001db2:	79913c23          	sd	s9,1944(sp)
    80001db6:	79b13423          	sd	s11,1928(sp)
    80001dba:	6785                	lui	a5,0x1
    80001dbc:	91010113          	addi	sp,sp,-1776
    80001dc0:	81078793          	addi	a5,a5,-2032 # 810 <_heap_size-0x37f0>
    80001dc4:	0818                	addi	a4,sp,16
    80001dc6:	00f70433          	add	s0,a4,a5
    80001dca:	8d2a                	mv	s10,a0
    ret = MLK_ERR_OUT_OF_MEMORY;
    goto cleanup;
  }

  /* Specification: Implements @[FIPS203, Section 7.3, Hash check] */
  ret = mlk_kem_check_sk(sk, context);
    80001dcc:	8532                	mv	a0,a2
{
    80001dce:	89ae                	mv	s3,a1
    80001dd0:	8a32                	mv	s4,a2
    80001dd2:	81f40413          	addi	s0,s0,-2017
  ret = mlk_kem_check_sk(sk, context);
    80001dd6:	dc8ff0ef          	jal	8000139e <mlkem_check_sk>
{
    80001dda:	9801                	andi	s0,s0,-32
  ret = mlk_kem_check_sk(sk, context);
    80001ddc:	597d                	li	s2,-1
  if (ret != 0)
    80001dde:	2a051763          	bnez	a0,8000208c <mlkem_dec+0x30a>
  ensures(0 <= return_value && return_value <= (MLKEM_Q - 1))
)
{
  /* The return value is in 0..MLKEM_Q-1, hence not altered by the
   * conversion to int16_t. */
  return (int16_t)((((uint32_t)u * MLKEM_Q) + 512) >> 10);
    80001de2:	6885                	lui	a7,0x1
    80001de4:	892a                	mv	s2,a0
    80001de6:	d018889b          	addiw	a7,a7,-767 # d01 <_heap_size-0x32ff>
  const uint8_t *pk = sk + MLKEM_INDCPA_SECRETKEYBYTES;
    80001dea:	4501                	li	a0,0
    for (k = 0; k < 4; k++)
    80001dec:	4e11                	li	t3,4
  for (j = 0; j < MLKEM_N / 4; j++)
    80001dee:	10000e93          	li	t4,256
    80001df2:	4305                	li	t1,1
    80001df4:	40a007b3          	neg	a5,a0
    80001df8:	1407f793          	andi	a5,a5,320
    80001dfc:	97ce                	add	a5,a5,s3
    80001dfe:	4801                	li	a6,0
      r->coeffs[4 * j + k] = mlk_scalar_decompress_d10(t[k]);
    80001e00:	00851f13          	slli	t5,a0,0x8
    t[0] = 0x3FF & ((base[0] >> 0) | ((uint16_t)base[1] << 8));
    80001e04:	0017c683          	lbu	a3,1(a5)
    80001e08:	0007c583          	lbu	a1,0(a5)
    for (k = 0; k < 4; k++)
    80001e0c:	4f81                	li	t6,0
    t[0] = 0x3FF & ((base[0] >> 0) | ((uint16_t)base[1] << 8));
    80001e0e:	00869713          	slli	a4,a3,0x8
    80001e12:	8f4d                	or	a4,a4,a1
    80001e14:	3ff77713          	andi	a4,a4,1023
    80001e18:	00e11c23          	sh	a4,24(sp)
    t[1] = 0x3FF & ((base[1] >> 2) | ((uint16_t)base[2] << 6));
    80001e1c:	0027c583          	lbu	a1,2(a5)
    80001e20:	0026d69b          	srliw	a3,a3,0x2
    80001e24:	0065971b          	slliw	a4,a1,0x6
    80001e28:	8f55                	or	a4,a4,a3
    80001e2a:	3ff77713          	andi	a4,a4,1023
    80001e2e:	00e11d23          	sh	a4,26(sp)
    t[2] = 0x3FF & ((base[2] >> 4) | ((uint16_t)base[3] << 4));
    80001e32:	0037c683          	lbu	a3,3(a5)
    80001e36:	0045d59b          	srliw	a1,a1,0x4
    80001e3a:	0046971b          	slliw	a4,a3,0x4
    80001e3e:	8f4d                	or	a4,a4,a1
    80001e40:	3ff77713          	andi	a4,a4,1023
    80001e44:	00e11e23          	sh	a4,28(sp)
    t[3] = 0x3FF & ((base[3] >> 6) | ((uint16_t)base[4] << 2));
    80001e48:	0047c703          	lbu	a4,4(a5)
    80001e4c:	0066d69b          	srliw	a3,a3,0x6
    80001e50:	0027171b          	slliw	a4,a4,0x2
    80001e54:	8f55                	or	a4,a4,a3
    80001e56:	00e11f23          	sh	a4,30(sp)
    for (k = 0; k < 4; k++)
    80001e5a:	6705                	lui	a4,0x1
    80001e5c:	80870713          	addi	a4,a4,-2040 # 808 <_heap_size-0x37f8>
    80001e60:	0814                	addi	a3,sp,16
    80001e62:	00e685b3          	add	a1,a3,a4
    80001e66:	80058593          	addi	a1,a1,-2048
    80001e6a:	0005d683          	lhu	a3,0(a1)
      r->coeffs[4 * j + k] = mlk_scalar_decompress_d10(t[k]);
    80001e6e:	010f873b          	addw	a4,t6,a6
    80001e72:	977a                	add	a4,a4,t5
    80001e74:	031686bb          	mulw	a3,a3,a7
    80001e78:	0706                	slli	a4,a4,0x1
    80001e7a:	9722                	add	a4,a4,s0
    for (k = 0; k < 4; k++)
    80001e7c:	2f85                	addiw	t6,t6,1
    80001e7e:	0589                	addi	a1,a1,2
    80001e80:	2006869b          	addiw	a3,a3,512
    80001e84:	00a6d69b          	srliw	a3,a3,0xa
    80001e88:	40d71023          	sh	a3,1024(a4)
    80001e8c:	fdcf9fe3          	bne	t6,t3,80001e6a <mlkem_dec+0xe8>
  for (j = 0; j < MLKEM_N / 4; j++)
    80001e90:	2811                	addiw	a6,a6,4 # 8000004 <_stack_size+0x7ff0004>
    80001e92:	0795                	addi	a5,a5,5
    80001e94:	f7d818e3          	bne	a6,t4,80001e04 <mlkem_dec+0x82>
  for (i = 0; i < MLKEM_K; i++)
    80001e98:	24651d63          	bne	a0,t1,800020f2 <mlkem_dec+0x370>
    80001e9c:	40140b93          	addi	s7,s0,1025
    80001ea0:	7ffb8b93          	addi	s7,s7,2047
  return (int16_t)((((uint32_t)u * MLKEM_Q) + 8) >> 4);
    80001ea4:	6605                	lui	a2,0x1
    80001ea6:	28098713          	addi	a4,s3,640 # 2280 <_heap_size-0x1d80>
    80001eaa:	30098593          	addi	a1,s3,768
    80001eae:	86de                	mv	a3,s7
    80001eb0:	40140a93          	addi	s5,s0,1025
    80001eb4:	d016061b          	addiw	a2,a2,-767 # d01 <_heap_size-0x32ff>
    r->coeffs[2 * i + 0] = mlk_scalar_decompress_d4((a[i] >> 0) & 0xF);
    80001eb8:	00074783          	lbu	a5,0(a4)
  for (i = 0; i < MLKEM_N / 2; i++)
    80001ebc:	0705                	addi	a4,a4,1
    80001ebe:	0691                	addi	a3,a3,4
    80001ec0:	8bbd                	andi	a5,a5,15
    80001ec2:	02c787bb          	mulw	a5,a5,a2
    80001ec6:	27a1                	addiw	a5,a5,8
    80001ec8:	0047d79b          	srliw	a5,a5,0x4
    80001ecc:	fef69e23          	sh	a5,-4(a3)
    r->coeffs[2 * i + 1] = mlk_scalar_decompress_d4((a[i] >> 4) & 0xF);
    80001ed0:	fff74783          	lbu	a5,-1(a4)
    80001ed4:	0047d79b          	srliw	a5,a5,0x4
    80001ed8:	02c787bb          	mulw	a5,a5,a2
    80001edc:	27a1                	addiw	a5,a5,8
    80001ede:	0047d79b          	srliw	a5,a5,0x4
    80001ee2:	fef69f23          	sh	a5,-2(a3)
  for (i = 0; i < MLKEM_N / 2; i++)
    80001ee6:	fce599e3          	bne	a1,a4,80001eb8 <mlkem_dec+0x136>
  mlk_polyvec_frombytes(sk, packedsk);
    80001eea:	85d2                	mv	a1,s4
    80001eec:	8522                	mv	a0,s0
    80001eee:	ce4fe0ef          	jal	800003d2 <mlkem_polyvec_frombytes>
  }

  mlk_unpack_ciphertext(b, v, c);
  mlk_unpack_sk(skpv, sk);

  mlk_polyvec_ntt(b);
    80001ef2:	40040493          	addi	s1,s0,1024
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	eb1fe0ef          	jal	80000da8 <mlkem_polyvec_ntt>
  mlk_polyvec_mulcache_compute(b_cache, b);
    80001efc:	00140693          	addi	a3,s0,1
    80001f00:	7ff68693          	addi	a3,a3,2047
    80001f04:	8536                	mv	a0,a3
    80001f06:	85a6                	mv	a1,s1
    80001f08:	e436                	sd	a3,8(sp)
    80001f0a:	888ff0ef          	jal	80000f92 <mlkem_polyvec_mulcache_compute>
  mlk_polyvec_basemul_acc_montgomery_cached_c(r, a, b, b_cache);
    80001f0e:	66a2                	ld	a3,8(sp)
    80001f10:	20140c13          	addi	s8,s0,513
    80001f14:	7ffc0c13          	addi	s8,s8,2047
    80001f18:	8626                	mv	a2,s1
    80001f1a:	85a2                	mv	a1,s0
    80001f1c:	8562                	mv	a0,s8
    80001f1e:	cfcfe0ef          	jal	8000041a <mlk_polyvec_basemul_acc_montgomery_cached_c>
  mlk_poly_invntt_tomont_c(r);
    80001f22:	8562                	mv	a0,s8
    80001f24:	f45fe0ef          	jal	80000e68 <mlk_poly_invntt_tomont_c>
    80001f28:	4781                	li	a5,0
    80001f2a:	00140c93          	addi	s9,s0,1
    80001f2e:	20140b13          	addi	s6,s0,513
  for (i = 0; i < MLKEM_N; i++)
    80001f32:	20000693          	li	a3,512
    r->coeffs[i] = (int16_t)(r->coeffs[i] - b->coeffs[i]);
    80001f36:	00fc0633          	add	a2,s8,a5
    80001f3a:	000bd703          	lhu	a4,0(s7)
    80001f3e:	00065603          	lhu	a2,0(a2)
  for (i = 0; i < MLKEM_N; i++)
    80001f42:	0789                	addi	a5,a5,2
    80001f44:	0b89                	addi	s7,s7,2
    r->coeffs[i] = (int16_t)(r->coeffs[i] - b->coeffs[i]);
    80001f46:	9f11                	subw	a4,a4,a2
    80001f48:	feeb9f23          	sh	a4,-2(s7)
  for (i = 0; i < MLKEM_N; i++)
    80001f4c:	fed795e3          	bne	a5,a3,80001f36 <mlkem_dec+0x1b4>
  mlk_poly_reduce_c(r);
    80001f50:	7ffa8513          	addi	a0,s5,2047
    80001f54:	dd7fe0ef          	jal	80000d2a <mlk_poly_reduce_c>
void mlk_poly_tomsg(uint8_t msg[MLKEM_INDCPA_MSGBYTES], const mlk_poly *r)
{
  unsigned i;
  mlk_assert_bound(r, MLKEM_N, 0, MLKEM_Q);

  for (i = 0; i < MLKEM_N / 8; i++)
    80001f58:	60140713          	addi	a4,s0,1537
    for (j = 0; j < 8; j++)
    __loop__(
      invariant(i <= MLKEM_N / 8 && j <= 8)
      decreases(8 - j))
    {
      uint32_t t = mlk_scalar_compress_d1(r->coeffs[8 * i + j]);
    80001f5c:	6585                	lui	a1,0x1
  uint32_t d0 = (uint32_t)u * 1290168;
    80001f5e:	0013b537          	lui	a0,0x13b
    80001f62:	7ff70713          	addi	a4,a4,2047
    80001f66:	4601                	li	a2,0
    80001f68:	60140b93          	addi	s7,s0,1537
    80001f6c:	95a2                	add	a1,a1,s0
    80001f6e:	fb85051b          	addiw	a0,a0,-72 # 13afb8 <_stack_size+0x12afb8>
  return (uint8_t)((d0 + ((uint32_t)1u << 30)) >> 31);
    80001f72:	40000337          	lui	t1,0x40000
    for (j = 0; j < 8; j++)
    80001f76:	4e21                	li	t3,8
  for (i = 0; i < MLKEM_N / 8; i++)
    80001f78:	10000893          	li	a7,256
    msg[i] = 0;
    80001f7c:	00070023          	sb	zero,0(a4)
    80001f80:	4801                	li	a6,0
    for (j = 0; j < 8; j++)
    80001f82:	4681                	li	a3,0
      uint32_t t = mlk_scalar_compress_d1(r->coeffs[8 * i + j]);
    80001f84:	00c687bb          	addw	a5,a3,a2
    80001f88:	0786                	slli	a5,a5,0x1
    80001f8a:	97ae                	add	a5,a5,a1
  uint32_t d0 = (uint32_t)u * 1290168;
    80001f8c:	c0079783          	lh	a5,-1024(a5)
    80001f90:	02a787bb          	mulw	a5,a5,a0
  return (uint8_t)((d0 + ((uint32_t)1u << 30)) >> 31);
    80001f94:	00f307bb          	addw	a5,t1,a5
    80001f98:	01f7d79b          	srliw	a5,a5,0x1f
      msg[i] |= (uint8_t)(t << j);
    80001f9c:	00d797bb          	sllw	a5,a5,a3
    80001fa0:	00f86833          	or	a6,a6,a5
    80001fa4:	01070023          	sb	a6,0(a4)
    for (j = 0; j < 8; j++)
    80001fa8:	2685                	addiw	a3,a3,1
    80001faa:	fdc69de3          	bne	a3,t3,80001f84 <mlkem_dec+0x202>
  for (i = 0; i < MLKEM_N / 8; i++)
    80001fae:	2621                	addiw	a2,a2,8
    80001fb0:	0705                	addi	a4,a4,1
    80001fb2:	fd1615e3          	bne	a2,a7,80001f7c <mlkem_dec+0x1fa>
  mlk_poly_tomsg(m, v);

cleanup:
  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  MLK_FREE(b_cache, mlk_polyvec_mulcache, 1, context);
    80001fb6:	20000593          	li	a1,512
    80001fba:	7ffc8513          	addi	a0,s9,2047
    80001fbe:	b9afe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(sb, mlk_poly, 1, context);
    80001fc2:	20000593          	li	a1,512
    80001fc6:	7ffb0513          	addi	a0,s6,2047 # 17ff <_heap_size-0x2801>
    80001fca:	b8efe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(v, mlk_poly, 1, context);
    80001fce:	7ffa8513          	addi	a0,s5,2047
    80001fd2:	20000593          	li	a1,512
    80001fd6:	b82fe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(skpv, mlk_polyvec, 1, context);
    80001fda:	40000593          	li	a1,1024
    80001fde:	8522                	mv	a0,s0
    80001fe0:	b78fe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(b, mlk_polyvec, 1, context);
    80001fe4:	40000593          	li	a1,1024
    80001fe8:	8526                	mv	a0,s1
    80001fea:	b6efe0ef          	jal	80000358 <mlk_zeroize>
  {
    goto cleanup;
  }

  /* Multitarget countermeasure for coins + contributory KEM */
  mlk_memcpy(buf + MLKEM_SYMBYTES,
    80001fee:	7ffb8b93          	addi	s7,s7,2047
    80001ff2:	02000613          	li	a2,32
    80001ff6:	620a0593          	addi	a1,s4,1568
    80001ffa:	00cb8533          	add	a0,s7,a2
    80001ffe:	a5afe0ef          	jal	80000258 <memcpy>
             sk + MLKEM_INDCCA_SECRETKEYBYTES - 2 * MLKEM_SYMBYTES,
             MLKEM_SYMBYTES);
  mlk_hash_g(kr, buf, 2 * MLKEM_SYMBYTES);
    80002002:	04000613          	li	a2,64
    80002006:	85de                	mv	a1,s7
    80002008:	8526                	mv	a0,s1
    8000200a:	be0ff0ef          	jal	800013ea <mlkem_sha3_512>

  /* Recompute and compare ciphertext */
  /* coins are in kr+MLKEM_SYMBYTES */
  ret = mlk_indcpa_enc(tmp, buf, pk, kr + MLKEM_SYMBYTES, context);
    8000200e:	42040693          	addi	a3,s0,1056
    80002012:	300a0613          	addi	a2,s4,768
    80002016:	85de                	mv	a1,s7
    80002018:	8522                	mv	a0,s0
    8000201a:	8f5ff0ef          	jal	8000190e <mlkem_indcpa_enc.isra.0>
  if (ret != 0)
  {
    goto cleanup;
  }

  fail = mlk_ct_memcmp(ct, tmp, MLKEM_INDCCA_CIPHERTEXTBYTES);
    8000201e:	30000613          	li	a2,768
    80002022:	85a2                	mv	a1,s0
    80002024:	854e                	mv	a0,s3
    80002026:	ffffe0ef          	jal	80001024 <mlk_ct_memcmp>

  /* Compute rejection key */
  mlk_memcpy(tmp, sk + MLKEM_INDCCA_SECRETKEYBYTES - MLKEM_SYMBYTES,
    8000202a:	02000613          	li	a2,32
    8000202e:	640a0593          	addi	a1,s4,1600
  int32_t tmp = mlk_value_barrier_i32(-((int32_t)x));
    80002032:	40a00abb          	negw	s5,a0
    80002036:	8522                	mv	a0,s0
    80002038:	a20fe0ef          	jal	80000258 <memcpy>
             MLKEM_SYMBYTES);
  mlk_memcpy(tmp + MLKEM_SYMBYTES, ct, MLKEM_INDCCA_CIPHERTEXTBYTES);
    8000203c:	30000613          	li	a2,768
    80002040:	85ce                	mv	a1,s3
    80002042:	02040513          	addi	a0,s0,32
    80002046:	a12fe0ef          	jal	80000258 <memcpy>
  mlk_hash_j(ss, tmp, MLKEM_SYMBYTES + MLKEM_INDCCA_CIPHERTEXTBYTES);
    8000204a:	856a                	mv	a0,s10
    8000204c:	32000693          	li	a3,800
    80002050:	8622                	mv	a2,s0
    80002052:	02000593          	li	a1,32
    80002056:	ac8ff0ef          	jal	8000131e <mlkem_shake256>
  requires(memory_no_alias(x, len))
  assigns(memory_slice(r, len))
  ensures(forall(i, 0, len, (r[i] == (b == 0 ? x[i] : old(r)[i])))))
{
  size_t i;
  for (i = 0; i < len; i++)
    8000205a:	4701                	li	a4,0
    8000205c:	02000513          	li	a0,32
  __loop__(
    invariant(i <= len)
    invariant(forall(k, 0, i, r[k] == (b == 0 ? x[k] : loop_entry(r)[k])))
    decreases(len - i))
  {
    r[i] = mlk_ct_sel_uint8(r[i], x[i], b);
    80002060:	00e487b3          	add	a5,s1,a4
    80002064:	0007c683          	lbu	a3,0(a5)
    80002068:	00ed05b3          	add	a1,s10,a4
__contract__(ensures(return_value == 0)) { return mlk_ct_opt_blocker_u64; }
    8000206c:	8101b783          	ld	a5,-2032(gp) # 800034f0 <mlkem_ct_opt_blocker_u64>
  return b ^ (mlk_ct_cmask_nonzero_u8(cond) & (a ^ b));
    80002070:	0005c603          	lbu	a2,0(a1) # 1000 <_heap_size-0x3000>
  for (i = 0; i < len; i++)
    80002074:	0705                	addi	a4,a4,1
__contract__(ensures(return_value == b)) { return (b ^ mlk_ct_get_optblocker_i32()); }
    80002076:	00fac7b3          	xor	a5,s5,a5
  return b ^ (mlk_ct_cmask_nonzero_u8(cond) & (a ^ b));
    8000207a:	8e35                	xor	a2,a2,a3
  tmp >>= 16;
    8000207c:	4107d79b          	sraiw	a5,a5,0x10
  return b ^ (mlk_ct_cmask_nonzero_u8(cond) & (a ^ b));
    80002080:	8ff1                	and	a5,a5,a2
    80002082:	8ebd                	xor	a3,a3,a5
    r[i] = mlk_ct_sel_uint8(r[i], x[i], b);
    80002084:	00d58023          	sb	a3,0(a1)
  for (i = 0; i < len; i++)
    80002088:	fca71ce3          	bne	a4,a0,80002060 <mlkem_dec+0x2de>
  mlk_ct_cmov_zero(ss, kr, MLKEM_SYMBYTES, fail);

cleanup:
  /* Specification: Partially implements
   * @[FIPS203, Section 3.3, Destruction of intermediate values] */
  MLK_FREE(tmp, uint8_t, MLKEM_SYMBYTES + MLKEM_INDCCA_CIPHERTEXTBYTES,
    8000208c:	8522                	mv	a0,s0
    8000208e:	32000593          	li	a1,800
    80002092:	ac6fe0ef          	jal	80000358 <mlk_zeroize>
           context);
  MLK_FREE(kr, uint8_t, 2 * MLKEM_SYMBYTES, context);
    80002096:	40040513          	addi	a0,s0,1024
    8000209a:	04000593          	li	a1,64
    8000209e:	abafe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(buf, uint8_t, 2 * MLKEM_SYMBYTES, context);
    800020a2:	60140413          	addi	s0,s0,1537
    800020a6:	7ff40513          	addi	a0,s0,2047
    800020aa:	04000593          	li	a1,64
    800020ae:	aaafe0ef          	jal	80000358 <mlk_zeroize>

  return ret;
}
    800020b2:	6f010113          	addi	sp,sp,1776
    800020b6:	7e813083          	ld	ra,2024(sp)
    800020ba:	854a                	mv	a0,s2
    800020bc:	7e013403          	ld	s0,2016(sp)
    800020c0:	7d813483          	ld	s1,2008(sp)
    800020c4:	7d013903          	ld	s2,2000(sp)
    800020c8:	7c813983          	ld	s3,1992(sp)
    800020cc:	7c013a03          	ld	s4,1984(sp)
    800020d0:	7b813a83          	ld	s5,1976(sp)
    800020d4:	7b013b03          	ld	s6,1968(sp)
    800020d8:	7a813b83          	ld	s7,1960(sp)
    800020dc:	7a013c03          	ld	s8,1952(sp)
    800020e0:	79813c83          	ld	s9,1944(sp)
    800020e4:	79013d03          	ld	s10,1936(sp)
    800020e8:	78813d83          	ld	s11,1928(sp)
    800020ec:	7f010113          	addi	sp,sp,2032
    800020f0:	8082                	ret
  for (i = 0; i < MLKEM_K; i++)
    800020f2:	4505                	li	a0,1
    800020f4:	b301                	j	80001df4 <mlkem_dec+0x72>

00000000800020f6 <mlkem_enc_derand>:
{
    800020f6:	7115                	addi	sp,sp,-224
    800020f8:	e9a2                	sd	s0,208(sp)
    800020fa:	f952                	sd	s4,176(sp)
    800020fc:	02f10413          	addi	s0,sp,47
    80002100:	8a2a                	mv	s4,a0
  ret = mlk_kem_check_pk(pk, context);
    80002102:	8532                	mv	a0,a2
{
    80002104:	e5a6                	sd	s1,200(sp)
    80002106:	e1ca                	sd	s2,192(sp)
    80002108:	fd4e                	sd	s3,184(sp)
    8000210a:	f556                	sd	s5,168(sp)
    8000210c:	ed86                	sd	ra,216(sp)
    8000210e:	8aae                	mv	s5,a1
    80002110:	89b2                	mv	s3,a2
    80002112:	e436                	sd	a3,8(sp)
    80002114:	9801                	andi	s0,s0,-32
  ret = mlk_kem_check_pk(pk, context);
    80002116:	f49fe0ef          	jal	8000105e <mlkem_check_pk>
  if (ret != 0)
    8000211a:	04040913          	addi	s2,s0,64
  ret = mlk_kem_check_pk(pk, context);
    8000211e:	54fd                	li	s1,-1
  if (ret != 0)
    80002120:	e131                	bnez	a0,80002164 <mlkem_enc_derand+0x6e>
  mlk_memcpy(buf, coins, MLKEM_SYMBYTES);
    80002122:	65a2                	ld	a1,8(sp)
    80002124:	02000613          	li	a2,32
    80002128:	84aa                	mv	s1,a0
    8000212a:	854a                	mv	a0,s2
    8000212c:	92cfe0ef          	jal	80000258 <memcpy>
  mlk_hash_h(buf + MLKEM_SYMBYTES, pk, MLKEM_INDCCA_PUBLICKEYBYTES);
    80002130:	32000613          	li	a2,800
    80002134:	85ce                	mv	a1,s3
    80002136:	06040513          	addi	a0,s0,96
    8000213a:	a2aff0ef          	jal	80001364 <mlkem_sha3_256>
  mlk_hash_g(kr, buf, 2 * MLKEM_SYMBYTES);
    8000213e:	04000613          	li	a2,64
    80002142:	85ca                	mv	a1,s2
    80002144:	8522                	mv	a0,s0
    80002146:	aa4ff0ef          	jal	800013ea <mlkem_sha3_512>
  ret = mlk_indcpa_enc(ct, buf, pk, kr + MLKEM_SYMBYTES, context);
    8000214a:	864e                	mv	a2,s3
    8000214c:	85ca                	mv	a1,s2
    8000214e:	8552                	mv	a0,s4
    80002150:	02040693          	addi	a3,s0,32
    80002154:	fbaff0ef          	jal	8000190e <mlkem_indcpa_enc.isra.0>
  mlk_memcpy(ss, kr, MLKEM_SYMBYTES);
    80002158:	02000613          	li	a2,32
    8000215c:	85a2                	mv	a1,s0
    8000215e:	8556                	mv	a0,s5
    80002160:	8f8fe0ef          	jal	80000258 <memcpy>
  MLK_FREE(kr, uint8_t, 2 * MLKEM_SYMBYTES, context);
    80002164:	8522                	mv	a0,s0
    80002166:	04000593          	li	a1,64
    8000216a:	9eefe0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(buf, uint8_t, 2 * MLKEM_SYMBYTES, context);
    8000216e:	854a                	mv	a0,s2
    80002170:	04000593          	li	a1,64
    80002174:	9e4fe0ef          	jal	80000358 <mlk_zeroize>
}
    80002178:	60ee                	ld	ra,216(sp)
    8000217a:	644e                	ld	s0,208(sp)
    8000217c:	690e                	ld	s2,192(sp)
    8000217e:	79ea                	ld	s3,184(sp)
    80002180:	7a4a                	ld	s4,176(sp)
    80002182:	7aaa                	ld	s5,168(sp)
    80002184:	8526                	mv	a0,s1
    80002186:	64ae                	ld	s1,200(sp)
    80002188:	612d                	addi	sp,sp,224
    8000218a:	8082                	ret

000000008000218c <mlkem_enc>:
{
    8000218c:	711d                	addi	sp,sp,-96
    8000218e:	02f10793          	addi	a5,sp,47
    80002192:	e4a6                	sd	s1,72(sp)
    80002194:	fe07f493          	andi	s1,a5,-32
    80002198:	e8a2                	sd	s0,80(sp)
    8000219a:	e0ca                	sd	s2,64(sp)
    8000219c:	842a                	mv	s0,a0
    8000219e:	892e                	mv	s2,a1
 */
MLK_MUST_CHECK_RETURN_VALUE
static MLK_INLINE int mlk_randombytes(uint8_t *out, size_t outlen)
__contract__(
  requires(memory_no_alias(out, outlen))
  assigns(memory_slice(out, outlen))) { return randombytes(out, outlen); }
    800021a0:	8526                	mv	a0,s1
    800021a2:	02000593          	li	a1,32
    800021a6:	ec86                	sd	ra,88(sp)
    800021a8:	e432                	sd	a2,8(sp)
    800021aa:	870fe0ef          	jal	8000021a <randombytes>
  if (mlk_randombytes(coins, MLKEM_SYMBYTES) != 0)
    800021ae:	e505                	bnez	a0,800021d6 <mlkem_enc+0x4a>
  ret = mlk_kem_enc_derand(ct, ss, pk, coins, context);
    800021b0:	6622                	ld	a2,8(sp)
    800021b2:	8522                	mv	a0,s0
    800021b4:	86a6                	mv	a3,s1
    800021b6:	85ca                	mv	a1,s2
    800021b8:	f3fff0ef          	jal	800020f6 <mlkem_enc_derand>
    800021bc:	842a                	mv	s0,a0
  MLK_FREE(coins, uint8_t, MLKEM_SYMBYTES, context);
    800021be:	8526                	mv	a0,s1
    800021c0:	02000593          	li	a1,32
    800021c4:	994fe0ef          	jal	80000358 <mlk_zeroize>
}
    800021c8:	60e6                	ld	ra,88(sp)
    800021ca:	8522                	mv	a0,s0
    800021cc:	6446                	ld	s0,80(sp)
    800021ce:	64a6                	ld	s1,72(sp)
    800021d0:	6906                	ld	s2,64(sp)
    800021d2:	6125                	addi	sp,sp,96
    800021d4:	8082                	ret
    ret = MLK_ERR_RNG_FAIL;
    800021d6:	5475                	li	s0,-3
    800021d8:	b7dd                	j	800021be <mlkem_enc+0x32>

00000000800021da <mlkem_indcpa_keypair_derand.isra.0>:
int mlk_indcpa_keypair_derand(uint8_t pk[MLKEM_INDCPA_PUBLICKEYBYTES],
    800021da:	92010113          	addi	sp,sp,-1760
    800021de:	6c113c23          	sd	ra,1752(sp)
    800021e2:	6c813823          	sd	s0,1744(sp)
    800021e6:	6c913423          	sd	s1,1736(sp)
    800021ea:	6d213023          	sd	s2,1728(sp)
    800021ee:	6b313c23          	sd	s3,1720(sp)
    800021f2:	6b413823          	sd	s4,1712(sp)
    800021f6:	6b613023          	sd	s6,1696(sp)
    800021fa:	69913423          	sd	s9,1672(sp)
    800021fe:	69a13023          	sd	s10,1664(sp)
    80002202:	6b513423          	sd	s5,1704(sp)
    80002206:	69713c23          	sd	s7,1688(sp)
    8000220a:	69813823          	sd	s8,1680(sp)
    8000220e:	80010113          	addi	sp,sp,-2048
    80002212:	80010113          	addi	sp,sp,-2048
    80002216:	01f10413          	addi	s0,sp,31
  mlk_memcpy(coins_with_domain_separator, coins, MLKEM_SYMBYTES);
    8000221a:	6905                	lui	s2,0x1
int mlk_indcpa_keypair_derand(uint8_t pk[MLKEM_INDCPA_PUBLICKEYBYTES],
    8000221c:	9801                	andi	s0,s0,-32
  mlk_memcpy(coins_with_domain_separator, coins, MLKEM_SYMBYTES);
    8000221e:	64090913          	addi	s2,s2,1600 # 1640 <_heap_size-0x29c0>
int mlk_indcpa_keypair_derand(uint8_t pk[MLKEM_INDCPA_PUBLICKEYBYTES],
    80002222:	8caa                	mv	s9,a0
    80002224:	8d2e                	mv	s10,a1
  mlk_memcpy(coins_with_domain_separator, coins, MLKEM_SYMBYTES);
    80002226:	01240533          	add	a0,s0,s2
int mlk_indcpa_keypair_derand(uint8_t pk[MLKEM_INDCPA_PUBLICKEYBYTES],
    8000222a:	85b2                	mv	a1,a2
  mlk_memcpy(coins_with_domain_separator, coins, MLKEM_SYMBYTES);
    8000222c:	02000613          	li	a2,32
    80002230:	828fe0ef          	jal	80000258 <memcpy>
  mlk_hash_g(buf, coins_with_domain_separator, MLKEM_SYMBYTES + 1);
    80002234:	6585                	lui	a1,0x1
    80002236:	60058593          	addi	a1,a1,1536 # 1600 <_heap_size-0x2a00>
    8000223a:	00b404b3          	add	s1,s0,a1
  coins_with_domain_separator[MLKEM_SYMBYTES] = MLKEM_K;
    8000223e:	6985                	lui	s3,0x1
    80002240:	99a2                	add	s3,s3,s0
  mlk_hash_g(buf, coins_with_domain_separator, MLKEM_SYMBYTES + 1);
    80002242:	012405b3          	add	a1,s0,s2
    80002246:	8526                	mv	a0,s1
  coins_with_domain_separator[MLKEM_SYMBYTES] = MLKEM_K;
    80002248:	4b09                	li	s6,2
  mlk_hash_g(buf, coins_with_domain_separator, MLKEM_SYMBYTES + 1);
    8000224a:	02100613          	li	a2,33
  coins_with_domain_separator[MLKEM_SYMBYTES] = MLKEM_K;
    8000224e:	67698023          	sb	s6,1632(s3) # 1660 <_heap_size-0x29a0>
  mlk_hash_g(buf, coins_with_domain_separator, MLKEM_SYMBYTES + 1);
    80002252:	998ff0ef          	jal	800013ea <mlkem_sha3_512>
  mlk_memcpy(extkey[0], seed, MLKEM_SYMBYTES);
    80002256:	02048913          	addi	s2,s1,32
  mlk_gen_matrix(a, publicseed, 0 /* no transpose */);
    8000225a:	85a6                	mv	a1,s1
    8000225c:	6485                	lui	s1,0x1
    8000225e:	4601                	li	a2,0
    80002260:	8522                	mv	a0,s0
    80002262:	40048493          	addi	s1,s1,1024 # 1400 <_heap_size-0x2c00>
    80002266:	94a2                	add	s1,s1,s0
    80002268:	e1aff0ef          	jal	80001882 <mlkem_gen_matrix>
    8000226c:	85ca                	mv	a1,s2
    8000226e:	02000613          	li	a2,32
    80002272:	8526                	mv	a0,s1
    80002274:	fe5fd0ef          	jal	80000258 <memcpy>
  mlk_memcpy(extkey[1], seed, MLKEM_SYMBYTES);
    80002278:	85ca                	mv	a1,s2
    8000227a:	02000613          	li	a2,32
    8000227e:	04048513          	addi	a0,s1,64
    80002282:	fd7fd0ef          	jal	80000258 <memcpy>
  mlk_memcpy(extkey[2], seed, MLKEM_SYMBYTES);
    80002286:	85ca                	mv	a1,s2
    80002288:	02000613          	li	a2,32
    8000228c:	08048513          	addi	a0,s1,128
    80002290:	fc9fd0ef          	jal	80000258 <memcpy>
  mlk_memcpy(extkey[3], seed, MLKEM_SYMBYTES);
    80002294:	85ca                	mv	a1,s2
    80002296:	02000613          	li	a2,32
    8000229a:	0c048513          	addi	a0,s1,192
    8000229e:	fbbfd0ef          	jal	80000258 <memcpy>
  extkey[1][MLKEM_SYMBYTES] = nonce1;
    800022a2:	4785                	li	a5,1
  mlk_prf_eta1(buf[0], extkey[0]);
    800022a4:	40140913          	addi	s2,s0,1025
    800022a8:	7ff90913          	addi	s2,s2,2047
  extkey[1][MLKEM_SYMBYTES] = nonce1;
    800022ac:	46f98023          	sb	a5,1120(s3)
  extkey[3][MLKEM_SYMBYTES] = nonce3;
    800022b0:	478d                	li	a5,3
    800022b2:	4ef98023          	sb	a5,1248(s3)
  mlk_prf_eta1(buf[0], extkey[0]);
    800022b6:	8626                	mv	a2,s1
  extkey[0][MLKEM_SYMBYTES] = nonce0;
    800022b8:	42098023          	sb	zero,1056(s3)
  extkey[2][MLKEM_SYMBYTES] = nonce2;
    800022bc:	4b698023          	sb	s6,1184(s3)
  mlk_prf_eta1(buf[0], extkey[0]);
    800022c0:	02100693          	li	a3,33
    800022c4:	0c000593          	li	a1,192
    800022c8:	854a                	mv	a0,s2
    800022ca:	854ff0ef          	jal	8000131e <mlkem_shake256>
  mlk_prf_eta1(buf[1], extkey[1]);
    800022ce:	04048613          	addi	a2,s1,64
    800022d2:	02100693          	li	a3,33
    800022d6:	0c000593          	li	a1,192
    800022da:	0c090513          	addi	a0,s2,192
    800022de:	840ff0ef          	jal	8000131e <mlkem_shake256>
  mlk_prf_eta1(buf[2], extkey[2]);
    800022e2:	08048613          	addi	a2,s1,128
    800022e6:	02100693          	li	a3,33
    800022ea:	0c000593          	li	a1,192
    800022ee:	18090513          	addi	a0,s2,384
    800022f2:	82cff0ef          	jal	8000131e <mlkem_shake256>
    mlk_prf_eta1(buf[3], extkey[3]);
    800022f6:	0c048613          	addi	a2,s1,192
    800022fa:	02100693          	li	a3,33
    800022fe:	0c000593          	li	a1,192
    80002302:	24090513          	addi	a0,s2,576
  mlk_poly_cbd3(r, buf);
    80002306:	00140a13          	addi	s4,s0,1
    mlk_prf_eta1(buf[3], extkey[3]);
    8000230a:	814ff0ef          	jal	8000131e <mlkem_shake256>
  mlk_poly_cbd3(r, buf);
    8000230e:	7ffa0a13          	addi	s4,s4,2047
    80002312:	85ca                	mv	a1,s2
    80002314:	8552                	mv	a0,s4
    80002316:	a0afe0ef          	jal	80000520 <mlkem_poly_cbd3>
    8000231a:	0c090593          	addi	a1,s2,192
    8000231e:	200a0513          	addi	a0,s4,512
    80002322:	9fefe0ef          	jal	80000520 <mlkem_poly_cbd3>
    80002326:	854e                	mv	a0,s3
    80002328:	18090593          	addi	a1,s2,384
    8000232c:	9f4fe0ef          	jal	80000520 <mlkem_poly_cbd3>
    80002330:	20098513          	addi	a0,s3,512
    80002334:	24090593          	addi	a1,s2,576
    80002338:	9e8fe0ef          	jal	80000520 <mlkem_poly_cbd3>
  mlk_zeroize(buf, sizeof(buf));
    8000233c:	30000593          	li	a1,768
    80002340:	854a                	mv	a0,s2
    80002342:	816fe0ef          	jal	80000358 <mlk_zeroize>
  mlk_zeroize(extkey, sizeof(extkey));
    80002346:	10000593          	li	a1,256
    8000234a:	8526                	mv	a0,s1
    8000234c:	80cfe0ef          	jal	80000358 <mlk_zeroize>
  mlk_polyvec_ntt(skpv);
    80002350:	8552                	mv	a0,s4
    80002352:	a57fe0ef          	jal	80000da8 <mlkem_polyvec_ntt>
  mlk_polyvec_ntt(e);
    80002356:	854e                	mv	a0,s3
    80002358:	a51fe0ef          	jal	80000da8 <mlkem_polyvec_ntt>
  mlk_polyvec_mulcache_compute(skpv_cache, skpv);
    8000235c:	8526                	mv	a0,s1
    8000235e:	85d2                	mv	a1,s4
    80002360:	c33fe0ef          	jal	80000f92 <mlkem_polyvec_mulcache_compute>
  mlk_polyvec_basemul_acc_montgomery_cached_c(r, a, b, b_cache);
    80002364:	86a6                	mv	a3,s1
    80002366:	8652                	mv	a2,s4
    80002368:	85a2                	mv	a1,s0
    8000236a:	854a                	mv	a0,s2
    8000236c:	8aefe0ef          	jal	8000041a <mlk_polyvec_basemul_acc_montgomery_cached_c>
    80002370:	20090993          	addi	s3,s2,512
    80002374:	86a6                	mv	a3,s1
    80002376:	40040593          	addi	a1,s0,1024
    8000237a:	854e                	mv	a0,s3
    8000237c:	8652                	mv	a2,s4
    8000237e:	89cfe0ef          	jal	8000041a <mlk_polyvec_basemul_acc_montgomery_cached_c>
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80002382:	757d                	lui	a0,0xfffff
  r = a - ((int32_t)t * MLKEM_Q);
    80002384:	75fd                	lui	a1,0xfffff
    80002386:	86ca                	mv	a3,s2
    80002388:	40140713          	addi	a4,s0,1025
    8000238c:	00140493          	addi	s1,s0,1
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    80002390:	54900813          	li	a6,1353
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    80002394:	3015051b          	addiw	a0,a0,769 # fffffffffffff301 <_stack_start+0xffffffff7ffe7141>
  r = a - ((int32_t)t * MLKEM_Q);
    80002398:	2ff5859b          	addiw	a1,a1,767 # fffffffffffff2ff <_stack_start+0xffffffff7ffe713f>
    8000239c:	00069603          	lh	a2,0(a3)
  for (i = 0; i < MLKEM_N; i++)
    800023a0:	0689                	addi	a3,a3,2
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    800023a2:	0306063b          	mulw	a2,a2,a6
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    800023a6:	02c507bb          	mulw	a5,a0,a2
  r = a - ((int32_t)t * MLKEM_Q);
    800023aa:	0107979b          	slliw	a5,a5,0x10
    800023ae:	4107d79b          	sraiw	a5,a5,0x10
    800023b2:	02b787bb          	mulw	a5,a5,a1
    800023b6:	9fb1                	addw	a5,a5,a2
  r = r >> 16;
    800023b8:	4107d79b          	sraiw	a5,a5,0x10
  return (int16_t)r;
    800023bc:	fef69f23          	sh	a5,-2(a3)
  for (i = 0; i < MLKEM_N; i++)
    800023c0:	fcd99ee3          	bne	s3,a3,8000239c <mlkem_indcpa_keypair_derand.isra.0+0x1c2>
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    800023c4:	75fd                	lui	a1,0xfffff
  r = a - ((int32_t)t * MLKEM_Q);
    800023c6:	767d                	lui	a2,0xfffff
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    800023c8:	54900513          	li	a0,1353
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    800023cc:	3015859b          	addiw	a1,a1,769 # fffffffffffff301 <_stack_start+0xffffffff7ffe7141>
  r = a - ((int32_t)t * MLKEM_Q);
    800023d0:	2ff6061b          	addiw	a2,a2,767 # fffffffffffff2ff <_stack_start+0xffffffff7ffe713f>
    800023d4:	20091683          	lh	a3,512(s2)
  for (i = 0; i < MLKEM_N; i++)
    800023d8:	0909                	addi	s2,s2,2
  res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
    800023da:	02a686bb          	mulw	a3,a3,a0
  const uint16_t a_inverted = (a_reduced * QINV) & UINT16_MAX;
    800023de:	02d587bb          	mulw	a5,a1,a3
  r = a - ((int32_t)t * MLKEM_Q);
    800023e2:	0107979b          	slliw	a5,a5,0x10
    800023e6:	4107d79b          	sraiw	a5,a5,0x10
    800023ea:	02c787bb          	mulw	a5,a5,a2
    800023ee:	9fb5                	addw	a5,a5,a3
  r = r >> 16;
    800023f0:	4107d79b          	sraiw	a5,a5,0x10
  return (int16_t)r;
    800023f4:	1ef91f23          	sh	a5,510(s2)
  for (i = 0; i < MLKEM_N; i++)
    800023f8:	fd299ee3          	bne	s3,s2,800023d4 <mlkem_indcpa_keypair_derand.isra.0+0x1fa>
    mlk_poly_add(&r->vec[i], &b->vec[i]);
    800023fc:	6a85                	lui	s5,0x1
    800023fe:	7ff70a13          	addi	s4,a4,2047
    80002402:	015409b3          	add	s3,s0,s5
    80002406:	85ce                	mv	a1,s3
    80002408:	8552                	mv	a0,s4
    8000240a:	f5ffd0ef          	jal	80000368 <mlkem_poly_add>
    8000240e:	20098593          	addi	a1,s3,512
    80002412:	200a0513          	addi	a0,s4,512
    80002416:	f53fd0ef          	jal	80000368 <mlkem_poly_add>
  mlk_polyvec_reduce(pkpv);
    8000241a:	8552                	mv	a0,s4
    8000241c:	977fe0ef          	jal	80000d92 <mlkem_polyvec_reduce>
  mlk_polyvec_reduce(skpv);
    80002420:	7ff48913          	addi	s2,s1,2047
    80002424:	854a                	mv	a0,s2
    80002426:	96dfe0ef          	jal	80000d92 <mlkem_polyvec_reduce>
  mlk_polyvec_tobytes(r, sk);
    8000242a:	85ca                	mv	a1,s2
    8000242c:	856a                	mv	a0,s10
    8000242e:	f61fd0ef          	jal	8000038e <mlkem_polyvec_tobytes>
  mlk_polyvec_tobytes(r, pk);
    80002432:	85d2                	mv	a1,s4
    80002434:	8566                	mv	a0,s9
    80002436:	f59fd0ef          	jal	8000038e <mlkem_polyvec_tobytes>
  mlk_memcpy(r + MLKEM_POLYVECBYTES, seed, MLKEM_SYMBYTES);
    8000243a:	600a8493          	addi	s1,s5,1536 # 1600 <_heap_size-0x2a00>
    8000243e:	02000613          	li	a2,32
    80002442:	009405b3          	add	a1,s0,s1
    80002446:	300c8513          	addi	a0,s9,768
    8000244a:	e0ffd0ef          	jal	80000258 <memcpy>
  MLK_FREE(skpv_cache, mlk_polyvec_mulcache, 1, context);
    8000244e:	400a8513          	addi	a0,s5,1024
    80002452:	9522                	add	a0,a0,s0
    80002454:	20000593          	li	a1,512
    80002458:	f01fd0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(skpv, mlk_polyvec, 1, context);
    8000245c:	854a                	mv	a0,s2
    8000245e:	40000593          	li	a1,1024
    80002462:	ef7fd0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(pkpv, mlk_polyvec, 1, context);
    80002466:	8552                	mv	a0,s4
    80002468:	40000593          	li	a1,1024
    8000246c:	eedfd0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(e, mlk_polyvec, 1, context);
    80002470:	854e                	mv	a0,s3
    80002472:	40000593          	li	a1,1024
    80002476:	ee3fd0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(a, mlk_polymat, 1, context);
    8000247a:	800a8593          	addi	a1,s5,-2048
    8000247e:	8522                	mv	a0,s0
    80002480:	ed9fd0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(coins_with_domain_separator, uint8_t, MLKEM_SYMBYTES + 1, context);
    80002484:	640a8513          	addi	a0,s5,1600
    80002488:	9522                	add	a0,a0,s0
    8000248a:	02100593          	li	a1,33
    8000248e:	ecbfd0ef          	jal	80000358 <mlk_zeroize>
  MLK_FREE(buf, uint8_t, 2 * MLKEM_SYMBYTES, context);
    80002492:	00940533          	add	a0,s0,s1
    80002496:	04000593          	li	a1,64
    8000249a:	ebffd0ef          	jal	80000358 <mlk_zeroize>
}
    8000249e:	6285                	lui	t0,0x1
    800024a0:	9116                	add	sp,sp,t0
    800024a2:	6d813083          	ld	ra,1752(sp)
    800024a6:	6d013403          	ld	s0,1744(sp)
    800024aa:	6c813483          	ld	s1,1736(sp)
    800024ae:	6c013903          	ld	s2,1728(sp)
    800024b2:	6b813983          	ld	s3,1720(sp)
    800024b6:	6b013a03          	ld	s4,1712(sp)
    800024ba:	6a813a83          	ld	s5,1704(sp)
    800024be:	6a013b03          	ld	s6,1696(sp)
    800024c2:	69813b83          	ld	s7,1688(sp)
    800024c6:	69013c03          	ld	s8,1680(sp)
    800024ca:	68813c83          	ld	s9,1672(sp)
    800024ce:	68013d03          	ld	s10,1664(sp)
    800024d2:	6e010113          	addi	sp,sp,1760
    800024d6:	8082                	ret

00000000800024d8 <mlkem_keypair_derand>:
{
    800024d8:	1101                	addi	sp,sp,-32
    800024da:	ec06                	sd	ra,24(sp)
    800024dc:	e822                	sd	s0,16(sp)
    800024de:	e426                	sd	s1,8(sp)
    800024e0:	e04a                	sd	s2,0(sp)
    800024e2:	842e                	mv	s0,a1
    800024e4:	84aa                	mv	s1,a0
    800024e6:	8932                	mv	s2,a2
  ret = mlk_indcpa_keypair_derand(pk, sk, coins, context);
    800024e8:	cf3ff0ef          	jal	800021da <mlkem_indcpa_keypair_derand.isra.0>
  mlk_memcpy(sk + MLKEM_INDCPA_SECRETKEYBYTES, pk, MLKEM_INDCCA_PUBLICKEYBYTES);
    800024ec:	85a6                	mv	a1,s1
    800024ee:	32000613          	li	a2,800
    800024f2:	30040513          	addi	a0,s0,768
    800024f6:	d63fd0ef          	jal	80000258 <memcpy>
  mlk_hash_h(sk + MLKEM_INDCCA_SECRETKEYBYTES - 2 * MLKEM_SYMBYTES, pk,
    800024fa:	85a6                	mv	a1,s1
    800024fc:	62040513          	addi	a0,s0,1568
    80002500:	32000613          	li	a2,800
    80002504:	e61fe0ef          	jal	80001364 <mlkem_sha3_256>
  mlk_memcpy(sk + MLKEM_INDCCA_SECRETKEYBYTES - MLKEM_SYMBYTES,
    80002508:	02000613          	li	a2,32
    8000250c:	00c905b3          	add	a1,s2,a2
    80002510:	64040513          	addi	a0,s0,1600
    80002514:	d45fd0ef          	jal	80000258 <memcpy>
}
    80002518:	60e2                	ld	ra,24(sp)
    8000251a:	6442                	ld	s0,16(sp)
    8000251c:	64a2                	ld	s1,8(sp)
    8000251e:	6902                	ld	s2,0(sp)
    80002520:	4501                	li	a0,0
    80002522:	6105                	addi	sp,sp,32
    80002524:	8082                	ret

0000000080002526 <mlkem_keypair>:
{
    80002526:	7119                	addi	sp,sp,-128
    80002528:	01f10793          	addi	a5,sp,31
    8000252c:	f4a6                	sd	s1,104(sp)
    8000252e:	fe07f493          	andi	s1,a5,-32
    80002532:	f0ca                	sd	s2,96(sp)
    80002534:	ecce                	sd	s3,88(sp)
    80002536:	892a                	mv	s2,a0
    80002538:	89ae                	mv	s3,a1
    8000253a:	8526                	mv	a0,s1
    8000253c:	04000593          	li	a1,64
    80002540:	f8a2                	sd	s0,112(sp)
    80002542:	fc86                	sd	ra,120(sp)
    80002544:	cd7fd0ef          	jal	8000021a <randombytes>
    ret = MLK_ERR_RNG_FAIL;
    80002548:	5475                	li	s0,-3
  if (mlk_randombytes(coins, 2 * MLKEM_SYMBYTES) != 0)
    8000254a:	e519                	bnez	a0,80002558 <mlkem_keypair+0x32>
    8000254c:	842a                	mv	s0,a0
  ret = mlk_kem_keypair_derand(pk, sk, coins, context);
    8000254e:	8626                	mv	a2,s1
    80002550:	85ce                	mv	a1,s3
    80002552:	854a                	mv	a0,s2
    80002554:	f85ff0ef          	jal	800024d8 <mlkem_keypair_derand>
  MLK_FREE(coins, uint8_t, 2 * MLKEM_SYMBYTES, context);
    80002558:	8526                	mv	a0,s1
    8000255a:	04000593          	li	a1,64
    8000255e:	dfbfd0ef          	jal	80000358 <mlk_zeroize>
}
    80002562:	70e6                	ld	ra,120(sp)
    80002564:	8522                	mv	a0,s0
    80002566:	7446                	ld	s0,112(sp)
    80002568:	74a6                	ld	s1,104(sp)
    8000256a:	7906                	ld	s2,96(sp)
    8000256c:	69e6                	ld	s3,88(sp)
    8000256e:	6109                	addi	sp,sp,128
    80002570:	8082                	ret

0000000080002572 <mlkem_keccakf1600_permute>:
  mlk_keccakf1600_permute_c(state);
    80002572:	81efe06f          	j	80000590 <mlk_keccakf1600_permute_c>
