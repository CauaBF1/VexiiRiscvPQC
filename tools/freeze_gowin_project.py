#!/usr/bin/env python3
"""Copy a prepared LiteX Gowin project into a new, hashed, portable folder.

Does not execute synthesis, PNR or programming. Use the bounded runner once.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('gateware',type=Path)
p.add_argument('output',type=Path)
a=p.parse_args();source=a.gateware.resolve();out=a.output.resolve()
if out.exists():raise SystemExit('Refusing existing physical project: '+str(out))
tcl=(source/'run.tcl').read_text();inputs=[];lines=[];names=set()
for line in tcl.splitlines():
    if line.startswith('add_file '):
        m=re.fullmatch(r'add_file\s+(?:"([^"\n]+)"|\{([^}\n]+)\}|([^\s]+))\s*',line)
        if not m:raise SystemExit('Unsupported Tcl add_file syntax: '+line)
        path=Path(next(x for x in m.groups() if x is not None))
        if not path.is_absolute():path=source/path
        if not path.is_file():raise SystemExit('Missing Tcl input: '+str(path))
        if path.name in names:raise SystemExit('Duplicate input name: '+path.name)
        names.add(path.name);inputs.append(path);lines.append('add_file {'+path.name+'}')
    elif re.match(r'\s*run\s',line):continue
    else:lines.append(line)
for path in source.glob('*.init'):
    if path.name in names:raise SystemExit('Duplicate init name: '+path.name)
    names.add(path.name);inputs.append(path)
for path in inputs:
    if path.suffix.lower() in ['.v','.sv']:
        for init in re.findall(r'\$readmem[hb]\("([^"\n]+)"',path.read_text()):
            if init not in names:raise SystemExit('Nonportable/missing memory initialization: '+init)
if not inputs:raise SystemExit('No project inputs found')
out.mkdir(parents=True)
for path in inputs:shutil.copy2(path,out/path.name)
(out/'run.tcl').write_text('\n'.join(lines+['run all'])+'\n')
manifest=[{'file':f.name,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in sorted(out.iterdir()) if f.is_file()]
(out/'inputs.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'project':str(out),'inputs':len(manifest),'physical_invocations':0}))
