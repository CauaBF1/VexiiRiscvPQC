#!/usr/bin/env python3
"""Prepare an isolated Tang Primer 20K SoC/BIOS, without invoking Gowin.

Uses dependencies from the activated LITEX_DIR, copying the mutable LiteX,
LiteX-Boards and CPU-data trees into a new output folder. The installed BIOS
and dependencies remain untouched. Run after `source env.sh`.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--output',type=Path,required=True)
p.add_argument('--software',choices=['none','both','montgomery-barrett'],default='montgomery-barrett')
a=p.parse_args();out=a.output.resolve()
if out.exists():raise SystemExit('Refusing existing output directory: '+str(out))
dep=Path(os.environ.get('LITEX_DIR',''))
if not dep.is_dir():raise SystemExit('Activate env.sh / set LITEX_DIR first')
for name in ['litex','litex-boards','pythondata-cpu-vexiiriscv']:
    if not (dep/name).is_dir():raise SystemExit('Missing dependency '+str(dep/name))
out.mkdir(parents=True)
versions={}
for name in ['litex','litex-boards','pythondata-cpu-vexiiriscv']:
    source=dep/name;destination=out/'deps'/name
    shutil.copytree(source,destination,ignore=shutil.ignore_patterns('__pycache__'))
    proc=subprocess.run(['git','-C',str(source),'rev-parse','HEAD'],capture_output=True,text=True)
    versions[name]={'source':str(source),'revision':proc.stdout.strip() if proc.returncode==0 else None}
env=os.environ.copy()
env.update(LITEX_DIR=str(out/'deps'),MLKEM_HW='montgomery-barrett',MLKEM_SW=a.software,MLKEM_BUILD_DIR=str(out/'build'),PYTHONDONTWRITEBYTECODE='1')
env.pop('MLKEM_ACCEL',None)
env['PYTHONPATH']=':'.join(str(out/'deps'/name) for name in ['litex','litex-boards','pythondata-cpu-vexiiriscv'])+':'+env.get('PYTHONPATH','')
command=[str(ROOT/'litex/tang_primer_20k/deploy.sh'),'--prepare']
data={'started':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':command,'dependencies':versions,'hardware':'montgomery-barrett','software':a.software,'physical_invocations':0,'gateware_compiled':False,'board_programmed':False,'source_sha256':{name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in ['src/main/scala/vexiiriscv/Param.scala','src/main/scala/vexiiriscv/execute/BarrettPlugin.scala','src/main/scala/vexiiriscv/execute/BarrettDatapath.scala','litex/tang_primer_20k/deploy.sh']}}
(out/'preparation.json').write_text(json.dumps(data,indent=2)+'\n')
start=time.monotonic()
with (out/'prepare.log').open('x') as log:
    child=subprocess.Popen(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
    try:code=child.wait(timeout=1200)
    except (subprocess.TimeoutExpired,KeyboardInterrupt):
        os.killpg(child.pid,signal.SIGTERM)
        try:child.wait(timeout=5)
        except subprocess.TimeoutExpired:os.killpg(child.pid,signal.SIGKILL);child.wait(timeout=5)
        code=124
data.update(exit_code=code,elapsed_seconds=time.monotonic()-start)
(out/'preparation.json').write_text(json.dumps(data,indent=2)+'\n')
print(json.dumps({'output':str(out),'exit_code':code,'physical_invocations':0}))
raise SystemExit(code)
