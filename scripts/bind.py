#!/usr/bin/env python3
"""Apply global shortcuts live via kglobalaccel D-Bus (daemon lives inside kwin).
stdin: TSV lines  component<TAB>action<TAB>keys(;-separated)<TAB>mode(set|add)
Env: DRY=1 -> print only.  Persistence is handled by the daemon itself."""
import json, os, subprocess, sys

DRY = os.environ.get("DRY") == "1"
RC = os.path.expanduser("~/.config/kglobalshortcutsrc")
MODS = {"Meta": 0x10000000, "Ctrl": 0x04000000, "Shift": 0x02000000, "Alt": 0x08000000}
NAMED = {"Tab": 0x01000001, "Return": 0x01000004, "Print": 0x01000009, "Left": 0x01000012,
         "Up": 0x01000013, "Right": 0x01000014, "Down": 0x01000015, "Comma": 0x2C, "Period": 0x2E,
         "Space": 0x20}

def parse(seq):
    v = 0
    for t in seq.split("+"):
        if t in MODS: v |= MODS[t]
        elif t in NAMED: v |= NAMED[t]
        elif len(t) == 1: v |= ord(t.upper())
        else: raise ValueError(f"unknown key token {t!r} in {seq!r}")
    return v

def name(v):
    inv = {x: k for k, x in NAMED.items()}
    parts = [k for k, m in MODS.items() if v & m]
    base = v & 0x01FFFFFF
    parts.append(inv.get(base, chr(base) if 32 < base < 127 else hex(base)))
    return "+".join(parts)

def bus(method, sig, *args, ret_json=False):
    cmd = ["busctl", "--user", "--json=short", "call", "org.kde.kglobalaccel", "/kglobalaccel",
           "org.kde.KGlobalAccel", method, sig, *map(str, args)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode: raise RuntimeError(r.stderr.strip())
    return json.loads(r.stdout)["data"][0] if r.stdout.strip() else None

def friendly_map():
    comp, names, cfn = None, {}, {}
    try: lines = open(RC, encoding="utf-8").read().splitlines()
    except OSError: return names, cfn
    for ln in lines:
        if ln.startswith("["):
            comp = ln.strip("[]").split("][")[-1]
        elif comp and "=" in ln:
            k, v = ln.split("=", 1)
            if k == "_k_friendly_name": cfn[comp] = v
            else:
                p = v.split(",", 2)
                if len(p) == 3: names[(comp, k)] = p[2]
    return names, cfn

NAMES, CFN = friendly_map()

def action_id(comp, act):
    return [comp, act, CFN.get(comp, comp), NAMES.get((comp, act), act)]

def get_keys(aid):
    try:
        out = []
        for k in bus("shortcutKeys", "as", len(aid), *aid):
            t = tuple(x for x in k[0] if x)
            if t: out.append(t)
        return out
    except Exception: return []

def set_keys(aid, keys):
    keys = [k for k in keys if k]
    args = [len(aid), *aid, len(keys)]
    for k in keys: args += [4, *k, *([0] * (4 - len(k)))]
    bus("setShortcutKeys", "asa(ai)u", *args, 6)

def owner(code):
    try: return bus("action", "i", code)
    except Exception: return []

for line in sys.stdin:
    line = line.rstrip("\n")
    if not line or line.startswith("#"): continue
    comp, act, keys, *rest = line.split("\t")
    mode = rest[0] if rest else "set"
    aid = action_id(comp, act)
    if comp.startswith("hyper-"):  # launcher components must be registered first
        n = comp[len("hyper-"):-len(".desktop")].capitalize()
        aid = [comp, act, f"Hyper {n}", f"Launch Hyper {n}"]
        if not DRY: bus("doRegister", "as", len(aid), *aid)
    want = [(parse(k),) for k in keys.split(";") if k]
    # free the keys from any other action
    for (code,) in want:
        o = owner(code)
        if o and o[:2] != aid[:2]:
            print(f"  steal {name(code)} from {o[0]}/{o[1]}")
            if not DRY:
                oid = list(o[:4]) if len(o) >= 4 else action_id(o[0], o[1])
                set_keys(oid, [k for k in get_keys(oid) if k != (code,)])
    cur = get_keys(aid)
    new = want if mode == "set" else cur + [k for k in want if k not in cur]
    print(f"{comp}/{act}: {[name(k[0]) for k in cur if k]} -> {[name(k[0]) for k in new]}")
    if not DRY: set_keys(aid, new)
