#!/usr/bin/env python3
"""Uma execução Gowin em projeto novo: até 1185 + 10 + 5 segundos.

Preparação e coleta não são executadas aqui. Não programa a placa. Saída zero
indica término da ferramenta; timing e KAT precisam de auditoria independente.
"""
import argparse
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import time


def members(pgid):
    found = []
    for f in Path('/proc').glob('[0-9]*/stat'):
        try:
            data = f.read_text().rsplit(')', 1)[1].split()
            if int(data[2]) == pgid:
                found.append({'pid': int(f.parent.name), 'state': data[0]})
        except (OSError, ValueError, IndexError):
            pass
    return found


def send(pgid, sig, state):
    try:
        os.killpg(pgid, sig)
        state.setdefault('termination', []).append(signal.Signals(sig).name)
    except ProcessLookupError:
        pass


def finish_group(child, state, grace, deadline):
    state['live_group_before_shutdown'] = any(m['state'] != 'Z' for m in members(child.pid))
    if state['status'] == 'tool_completed' and state['live_group_before_shutdown']:
        state['status'] = 'tool_completed_with_descendants_inconclusive'
    send(child.pid, signal.SIGTERM, state)
    term_deadline = min(time.monotonic() + grace, deadline - 5)
    while time.monotonic() < term_deadline:
        child.poll()
        if not any(m['state'] != 'Z' for m in members(child.pid)):
            break
        time.sleep(min(0.05, max(0, term_deadline - time.monotonic())))
    send(child.pid, signal.SIGKILL, state)
    while time.monotonic() < deadline - 0.5:
        child.poll()
        if not any(m['state'] != 'Z' for m in members(child.pid)):
            break
        time.sleep(min(0.05, max(0, deadline - 0.5 - time.monotonic())))
    # poll is nonblocking, including when a process is stuck in kernel state D.
    state['exit_code'] = child.poll()
    state['group_members_at_exit'] = members(child.pid)
    state['live_group_at_exit'] = any(m['state'] != 'Z' for m in state['group_members_at_exit'])
    try:
        os.killpg(child.pid, 0)
        state['group_present_at_exit'] = True
    except ProcessLookupError:
        state['group_present_at_exit'] = False


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project', type=Path, required=True)
    p.add_argument('--gw-sh', type=Path, required=True)
    p.add_argument('--timeout', type=float, default=1185)
    p.add_argument('--shutdown-seconds', type=float, default=10)
    a = p.parse_args()
    if not 0 < a.timeout <= 1185 or not 0 <= a.shutdown_seconds <= 10:
        p.error('timeout deve ser 0..1185 e shutdown-seconds 0..10')
    project = a.project.resolve()
    if not a.gw_sh.is_file() or not os.access(a.gw_sh, os.X_OK):
        p.error('gw-sh executável obrigatório')
    if (project / 'impl').exists() or (project / 'execution.json').exists() or list(project.glob('*.fs')):
        p.error('projeto já utilizado; outputs ou manifesto existentes')
    if not (project / 'run.tcl').is_file() or not (project / 'inputs.json').is_file():
        p.error('run.tcl e inputs.json obrigatórios')
    for entry in json.loads((project / 'inputs.json').read_text()):
        f = project / entry['file']
        if not f.resolve().is_relative_to(project) or hashlib.sha256(f.read_bytes()).hexdigest() != entry['sha256']:
            p.error('input congelado divergente: ' + entry['file'])
    # Same lock as the historical runner; neither permits concurrent experiments.
    lock = open(f'/tmp/mlkem_gowin_{os.getuid()}.lock', 'a')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        p.error('outro runner Gowin detém o lock')
    for proc in Path('/proc').glob('[0-9]*/comm'):
        try:
            if proc.read_text().strip() == 'gw_sh':
                p.error('gw_sh existente; inspecione antes de iniciar')
        except OSError:
            pass
    state = {'started_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
             'timeout_seconds': a.timeout, 'shutdown_seconds': a.shutdown_seconds,
             'maximum_invocation_seconds': a.timeout + a.shutdown_seconds + 5,
             'command': [str(a.gw_sh.resolve()), 'run.tcl'], 'status': 'starting',
             'timing_approved': False, 'load_permitted': False,
             'tcl_sha256': hashlib.sha256((project / 'run.tcl').read_bytes()).hexdigest()}

    def save():
        tmp = project / 'execution.json.tmp'
        tmp.write_text(json.dumps(state, indent=2) + '\n')
        tmp.replace(project / 'execution.json')

    with (project / 'execution.log').open('x') as log:
        started = time.monotonic()
        deadline = started + a.timeout + a.shutdown_seconds + 5
        child = None
        pending_signals = []

        def interrupt(signum, frame):
            # A signal during Popen must not throw before child is assigned.
            # The bounded polling loop observes this flag immediately afterward.
            pending_signals.append(signal.Signals(signum).name)

        originals = {sig: signal.getsignal(sig) for sig in (signal.SIGTERM, signal.SIGHUP, signal.SIGINT)}
        for sig in originals:
            signal.signal(sig, interrupt)
        try:
            save()
            if pending_signals:
                state['status'] = 'operator_interrupted'
            else:
                child = subprocess.Popen(state['command'], cwd=project, stdout=log,
                                         stderr=subprocess.STDOUT, start_new_session=True)
                state.update(status='running', pid=child.pid, pgid=child.pid)
                # This write is inside the same try/finally as Popen.
                save()
                while True:
                    if pending_signals:
                        state['status'] = 'operator_interrupted'
                        break
                    code = child.poll()
                    if code is not None:
                        state.update(status='tool_completed' if code == 0 else 'tool_failed', exit_code=code)
                        break
                    remaining = started + a.timeout - time.monotonic()
                    if remaining <= 0:
                        state['status'] = 'timeout_inconclusive'
                        break
                    try:
                        child.wait(timeout=min(0.1, remaining))
                    except subprocess.TimeoutExpired:
                        pass
        except Exception as error:
            state.update(status='runner_error_inconclusive', error=f'{type(error).__name__}: {error}')
        finally:
            for sig in originals:
                signal.signal(sig, signal.SIG_IGN)
            if pending_signals:
                state['received_signals'] = pending_signals
            if child is not None:
                # Drain descendants even if gw_sh itself returned before them,
                # including a failure to persist state immediately after launch.
                finish_group(child, state, a.shutdown_seconds, deadline)
            else:
                state.update(group_members_at_exit=[], live_group_at_exit=False,
                             group_present_at_exit=False, exit_code=None)
            state['elapsed_seconds'] = round(time.monotonic() - started, 3)
            state['budget_exceeded'] = time.monotonic() > deadline
            try:
                save()
            except OSError as error:
                state['final_persistence_error'] = str(error)
            finally:
                for sig, handler in originals.items():
                    signal.signal(sig, handler)
    print(json.dumps(state, indent=2))
    return 0 if (state['status'] == 'tool_completed' and not state['live_group_at_exit']
                 and 'final_persistence_error' not in state) else 1


if __name__ == '__main__':
    raise SystemExit(main())
