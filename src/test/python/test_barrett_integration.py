"""Patch transitions and actual deploy selection functions, without FPGA tools."""
import hashlib
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[3]
FW=ROOT/'src/main/c/vexii/mlkem512'
DEPLOY=ROOT/'litex/tang_primer_20k/deploy.sh'

class BarrettIntegrationSpec(unittest.TestCase):
    def select(self, hw, sw, action='--check', flags=False):
        source=DEPLOY.read_text()
        prelude=source.split('\nresolve_accel_config\n',1)[0]
        prelude=re.sub(r'^REPO_ROOT=.*$', 'REPO_ROOT='+shlex.quote(str(ROOT)), prelude, flags=re.M)
        suffix='\nresolve_accel_config\nprintf "%s\\n" "$VEXII_EFFECTIVE_ARGS"\n'
        if flags:
            block=source.split('BUILD_FLAGS=(--build)',1)[1].split('VEXII_FLAGS=()',1)[0]
            suffix+='BUILD_FLAGS=(--build)'+block+'printf "%s\\n" "${BUILD_FLAGS[*]}"\n'
        env={k:v for k,v in os.environ.items() if k not in ['MLKEM_ACCEL','MLKEM_HW','MLKEM_SW','VEXII_ARGS']}
        env.update(MLKEM_HW=hw,MLKEM_SW=sw)
        return subprocess.run(['bash','-c',prelude+suffix,'test',action],env=env,capture_output=True,text=True)

    def test_old_profiles_and_new_barrett_profiles(self):
        for profile,expected in [('none',[]),('both',['montmul','montred']),('all',['montmul','montred','keccak']),('barrett',['barrett']),('montgomery-barrett',['montmul','montred','barrett']),('all-barrett',['montmul','montred','keccak','barrett'])]:
            with self.subTest(profile=profile):
                result=self.select(profile,profile)
                self.assertEqual(result.returncode,0,result.stderr)
                for feature in ['montmul','montred','keccak','barrett']:
                    self.assertEqual('--with-'+feature in result.stdout,feature in expected)
                self.assertNotIn('--lsu-l1-ways=1',result.stdout)

    def test_software_cannot_request_missing_hardware(self):
        for hw,sw in [('both','montgomery-barrett'),('none','barrett'),('montgomery-barrett','all-barrett')]:
            result=self.select(hw,sw)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('exige a feature',result.stderr)

    def test_prepare_never_loads_or_invokes_gateware_compiler(self):
        result=self.select('montgomery-barrett','montgomery-barrett','--prepare',flags=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('--build',result.stdout)
        self.assertIn('--no-compile-gateware',result.stdout)
        self.assertNotIn('--load',result.stdout)

    def test_bios_header_rejects_missing_barrett(self):
        header=ROOT/'litex/tang_primer_20k/bios/mlkem_accel_select.h'
        for has_hw in [False,True]:
            command=['cc','-fsyntax-only','-x','c','-','-DMLK_USE_BARRETT']
            if has_hw:command+=['-DMLK_HW_HAS_BARRETT']
            result=subprocess.run(command,input='#include "'+str(header)+'"\n',text=True,capture_output=True)
            self.assertEqual(result.returncode==0,has_hw)

    def test_patch_clean_applied_idempotent_and_reverse(self):
        patch=(ROOT/'external/mlkem-native.patch').read_text()
        files=re.findall(r'^\+\+\+ b/(.+)$',patch,re.M)
        with tempfile.TemporaryDirectory() as folder:
            directory=Path(folder)
            for name in files:
                path=directory/name;path.parent.mkdir(parents=True,exist_ok=True)
                path.write_bytes(subprocess.check_output(['git','-C',str(ROOT/'external/mlkem-native'),'show','HEAD:'+name]))
            def hashes():return {name:hashlib.sha256((directory/name).read_bytes()).hexdigest() for name in files}
            original=hashes()
            def make(action):return subprocess.run(['make','-C',str(FW),action,'MLKEM_NATIVE_ROOT='+str(directory)],capture_output=True,text=True)
            first=make('prep');self.assertEqual(first.returncode,0,first.stdout+first.stderr)
            self.assertIn('MLK_USE_BARRETT',(directory/'mlkem/src/poly.c').read_text())
            applied=hashes();self.assertNotEqual(original,applied)
            second=make('prep');self.assertEqual(second.returncode,0,second.stdout+second.stderr)
            self.assertEqual(applied,hashes())
            reverse=make('unprep');self.assertEqual(reverse.returncode,0,reverse.stdout+reverse.stderr)
            self.assertEqual(original,hashes())
            # An incompatible tree must return failure, without pretending the
            # patch was absent or blindly writing partial changes elsewhere.
            (directory/'mlkem/src/poly.c').write_text('incompatible source\n')
            before=hashes();bad=make('prep');self.assertNotEqual(bad.returncode,0)
            self.assertEqual(before,hashes())
            bad_reverse=make('unprep');self.assertNotEqual(bad_reverse.returncode,0)
            self.assertEqual(before,hashes())

    def test_freezer_requires_local_memory_and_hashes_all_inputs(self):
        with tempfile.TemporaryDirectory() as folder:
            base=Path(folder);source=base/'gateware';source.mkdir()
            (source/'soc.v').write_text('module soc; initial $readmemh("rom.init", mem); endmodule\n')
            (source/'run.tcl').write_text('add_file "'+str(source/'soc.v')+'"\nrun all\n')
            command=[sys.executable,str(ROOT/'tools/freeze_gowin_project.py'),str(source)]
            absent=subprocess.run(command+[str(base/'missing')],capture_output=True,text=True)
            self.assertNotEqual(absent.returncode,0)
            self.assertFalse((base/'missing').exists())
            (source/'rom.init').write_text('00000000\n')
            result=subprocess.run(command+[str(base/'frozen')],capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            import json
            frozen=base/'frozen'
            manifest=json.loads((frozen/'inputs.json').read_text())
            self.assertEqual({e['file'] for e in manifest},{'soc.v','rom.init','run.tcl'})
            for entry in manifest:
                self.assertEqual(hashlib.sha256((frozen/entry['file']).read_bytes()).hexdigest(),entry['sha256'])
            self.assertNotIn(str(source),(frozen/'run.tcl').read_text())

if __name__=='__main__':unittest.main()
