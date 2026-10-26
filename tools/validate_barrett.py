#!/usr/bin/env python3
"""Build, test and compare Barrett locally. No SSH, Gowin or board programming.

Example: source env.sh; python3 tools/validate_barrett.py --output understanding/benchmarks/barrett_run all
Each command log is exclusive; use a fresh output directory to repeat a run.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import statistics
import subprocess
import sys
import time

ROOT=Path(__file__).resolve().parents[1]
FW=ROOT/'src/main/c/vexii/mlkem512'
OUT=None
MACROS={'c':[], 'mont':['MLK_USE_MONTMUL','MLK_USE_MONTRED'], 'mont-barrett':['MLK_USE_MONTMUL','MLK_USE_MONTRED','MLK_USE_BARRETT']}
SOURCES=['src/main/scala/vexiiriscv/Param.scala','src/main/scala/vexiiriscv/execute/BarrettDatapath.scala','src/main/scala/vexiiriscv/execute/BarrettPlugin.scala','external/mlkem-native/mlkem/src/poly.c','src/main/c/vexii/mlkem512/src/main.c']

def run(name,command,timeout=1200):
    log=OUT/(name+'.log');log.parent.mkdir(parents=True,exist_ok=True)
    if log.exists():raise SystemExit('Refusing log overwrite: '+str(log))
    data={'argv':command,'cwd':str(ROOT),'timeout_seconds':timeout,'source_sha256':{f:hashlib.sha256((ROOT/f).read_bytes()).hexdigest() for f in SOURCES},'physical_invocations':0}
    record=OUT/(name+'.command.json');record.write_text(json.dumps(data,indent=2)+'\n')
    started=time.monotonic()
    with log.open('x') as output:
        child=subprocess.Popen(command,cwd=ROOT,stdout=output,stderr=subprocess.STDOUT,start_new_session=True)
        try:code=child.wait(timeout=timeout)
        except (subprocess.TimeoutExpired,KeyboardInterrupt):
            os.killpg(child.pid,signal.SIGTERM)
            try:child.wait(timeout=5)
            except subprocess.TimeoutExpired:os.killpg(child.pid,signal.SIGKILL);child.wait(timeout=5)
            code=124
    data.update(exit_code=code,elapsed_seconds=time.monotonic()-started)
    record.write_text(json.dumps(data,indent=2)+'\n')
    if code:raise SystemExit(f'{name}: exit {code}; inspect {log}')
    print(name+' exit=0',flush=True)
    return log.read_text()

def compiler():
    prefix=os.environ.get('RISCV_NAME','riscv64-unknown-elf')
    home=os.environ.get('RISCV_PATH','')
    return str(Path(home)/'bin'/prefix)+'-gcc' if home else prefix+'-gcc'

def build():
    run('build/prep',['make','-C',str(FW),'prep'])
    for mode,macros in MACROS.items():
        for kind in ['bench','kat']:
            run('build/'+kind+'_'+mode,['make','-C',str(FW),'KAT='+('yes' if kind=='kat' else 'no'),'PROFILE=no','BENCH_ROUNDS=5','MARCH=rv32im_zicsr','MABI=ilp32','OBJDIR='+str(OUT/'firmware'/(kind+'_'+mode)),'CFLAGS_EXTRA='+' '.join('-D'+m for m in macros)])
    for xlen in [32,64]:
        run('build/micro'+str(xlen),[compiler(),'-march=rv'+str(xlen)+'im_zicsr','-mabi='+('ilp32' if xlen==32 else 'lp64'),'-Os','-g','-nostdlib','-nostartfiles','-ffreestanding','-mcmodel=medany','-I'+str(FW/'src'),'-T'+str(FW/'src/linker.ld'),str(FW/'src/crt.S'),str(ROOT/'src/test/c/barrett_protocol.c'),'-o',str(OUT/'firmware'/('micro'+str(xlen)+'.elf')),'-lgcc'])

def rtl():
    run('rtl',['sbt','testOnly vexiiriscv.ParamBarrettSpec vexiiriscv.execute.BarrettDatapathSpec vexiiriscv.ParamMontgomerySpec vexiiriscv.execute.MontgomeryDatapathSpec vexiiriscv.ParamKeccakSpec vexiiriscv.execute.KeccakF1600Spec'])

def sim(case):
    xlen=64 if case=='micro64' else 32
    if case.startswith('micro'):elf=OUT/'firmware'/(case+'.elf')
    elif case.startswith('kat-'):elf=OUT/'firmware'/('kat_'+case[4:])/'mlkem512.elf'
    else:elf=OUT/'firmware'/('bench_'+case)/'mlkem512.elf'
    args=['runMain','vexiiriscv.tester.TestBench','--load-elf',str(elf),'--xlen',str(xlen),'--with-rvm','--with-montmul','--with-montred','--with-barrett','--performance-counters','0','--reset-vector','2147483648','--no-rvls-check','--no-stdin','--fail-after','3000000000','--allow-bypass-from','0','--relaxed-branch','--fetch-l1','--fetch-l1-ways','2','--lsu-l1','--lsu-l1-ways','2','--with-lsu-bypass']
    text=run('sim/'+case,['sbt',' '.join(args)])
    if case.startswith('micro'):assert 'Barrett ISA PASS' in text
    elif case.startswith('kat-'):
        for name in ['pk_match','sk_match','ct_match','ss_match','kat_pass']:assert name+'=0x00000001' in text
    else:
        assert text.count('ss_match=0x0000000000000001')==5
        for name in ['keypair_ret','enc_ret','dec_ret']:assert text.count(name+'=0x0000000000000000')==5

def parse(file):
    rows=[]
    for line in file.read_text().splitlines():
        m=re.search(r'round=([0-9A-Fa-f]+)',line)
        if m:row={'round':int(m[1],16)};rows.append(row)
        m=re.search(r'(cycles_keypair|cycles_enc|cycles_dec|keypair_ret|enc_ret|dec_ret|ss_match)=0x([0-9A-Fa-f]+)',line)
        if m:row[m[1]]=int(m[2],16)
        m=re.search(r'(pk_prefix|ct_prefix|ss1_prefix|ss2_prefix)=([0-9A-Fa-f]+)',line)
        if m:row[m[1]]=m[2]
    assert len(rows)==5
    for row in rows:
        assert row['ss_match']==1 and all(row[k]==0 for k in ['keypair_ret','enc_ret','dec_ret'])
        row['cycles_total']=sum(row[k] for k in ['cycles_keypair','cycles_enc','cycles_dec'])
    return rows

def summarize():
    result={}
    for case in MACROS:
        assert json.loads((OUT/('sim/'+case+'.command.json')).read_text())['exit_code']==0
        rows=parse(OUT/('sim/'+case+'.log'))
        result[case]={'samples':rows,'medians':{k:statistics.median(r[k] for r in rows) for k in ['cycles_keypair','cycles_enc','cycles_dec','cycles_total']}}
    for i in range(5):
        for key in ['round','pk_prefix','ct_prefix','ss1_prefix','ss2_prefix']:assert len({result[case]['samples'][i][key] for case in MACROS})==1
    result['speedups_vs_c']={case:result['c']['medians']['cycles_total']/result[case]['medians']['cycles_total'] for case in MACROS}
    result['incremental_speedup_barrett']=result['mont']['medians']['cycles_total']/result['mont-barrett']['medians']['cycles_total']
    result['environment']={'xlen':32,'isa':'RV32IM','elf':'rv32im_zicsr/ilp32','optimization':'-Os','samples':5,'fetch_ways':2,'lsu_ways':2,'seed':2,'same_hardware':True,'keccak_in_hardware':False,'physical_measurement':False}
    (OUT/'BENCHMARK_RESULTADOS.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'speedups_vs_c':result['speedups_vs_c'],'incremental_speedup_barrett':result['incremental_speedup_barrett']},indent=2))

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--output',type=Path,default=ROOT/'understanding/benchmarks'/('barrett_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S')))
p.add_argument('action',choices=['build','rtl','sim','summarize','all'])
p.add_argument('--case',choices=['micro32','micro64','kat-c','kat-mont','kat-mont-barrett','c','mont','mont-barrett'],default='micro32')
a=p.parse_args();OUT=a.output.resolve();OUT.mkdir(parents=True,exist_ok=True)
print('Output: '+str(OUT),flush=True)
if a.action=='all':
    build();rtl()
    for case in ['micro32','micro64','kat-c','kat-mont','kat-mont-barrett','c','mont','mont-barrett']:sim(case)
    summarize()
elif a.action=='build':build()
elif a.action=='rtl':rtl()
elif a.action=='sim':sim(a.case)
else:summarize()
