#!/usr/bin/env python3
"""Live global-shortcut tool (kglobalaccel D-Bus; the daemon lives inside kwin).
  bind.py apply|check < bindings.tsv     TSV: component action keys(;-sep) mode(set|add)
  bind.py restore                        put every touched action back to its default keys
Env: DRY=1 -> print only.   State (touched actions, stolen keys): backup/state.json
  set = replace Meta-keys, keep non-Meta keys (Alt+F4, Ctrl+F1...);  add = append."""
import json, os, subprocess, sys

DRY = os.environ.get("DRY") == "1"
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(HERE, "backup", "state.json")
RC = os.path.expanduser("~/.config/kglobalshortcutsrc")
META = 0x10000000
MODS = {"Meta": META, "Ctrl": 0x04000000, "Shift": 0x02000000, "Alt": 0x08000000}
NAMED = {"Tab": 0x01000001, "Return": 0x01000004, "Print": 0x01000009, "Left": 0x01000012,
         "Up": 0x01000013, "Right": 0x01000014, "Down": 0x01000015, "Comma": 0x2C,
         "Period": 0x2E, "Space": 0x20}
NAMED.update({"PgUp": 0x01000016, "PgDown": 0x01000017, "Esc": 0x01000000, "Backspace": 0x01000003})
NAMED.update({f"F{i}": 0x0100002F + i for i in range(1, 13)})
INV = {v: k for k, v in NAMED.items()}

def parse(seq):
    v = 0
    for t in seq.split("+"):
        if t in MODS: v |= MODS[t]
        elif t in NAMED: v |= NAMED[t]
        elif len(t) == 1: v |= ord(t.upper())
        else: raise ValueError(f"unknown key token {t!r} in {seq!r}")
    return v

def name(v):
    parts = [k for k, m in MODS.items() if v & m]
    base = v & 0x01FFFFFF
    parts.append(INV.get(base, chr(base) if 32 < base < 127 else hex(base)))
    return "+".join(parts)

def bus(method, sig, *args):
    cmd = ["busctl", "--user", "--json=short", "call", "org.kde.kglobalaccel", "/kglobalaccel",
           "org.kde.KGlobalAccel", method, sig, *map(str, args)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode: raise RuntimeError(r.stderr.strip())
    return json.loads(r.stdout)["data"][0] if r.stdout.strip() else None

def friendly_maps():
    comp, names, cfn = None, {}, {}
    try: lines = open(RC, encoding="utf-8").read().splitlines()
    except OSError: return names, cfn
    for ln in lines:
        if ln.startswith("["): comp = ln.strip("[]").split("][")[-1]
        elif comp and "=" in ln:
            k, v = ln.split("=", 1)
            if k == "_k_friendly_name": cfn[comp] = v
            elif len(p := v.split(",", 2)) == 3: names[(comp, k)] = p[2]
    return names, cfn

NAMES, CFN = friendly_maps()

def action_id(comp, act):
    if comp.startswith("hyper-"):
        n = comp[len("hyper-"):-len(".desktop")].capitalize()
        return [comp, act, f"Hyper {n}", f"Launch Hyper {n}"]
    return [comp, act, CFN.get(comp, comp), NAMES.get((comp, act), act)]

def keys_of(method, aid):
    try:
        out = []
        for k in bus(method, "as", len(aid), *aid):
            t = tuple(x for x in k[0] if x)
            if t: out.append(t)
        return out
    except Exception: return []

get_keys = lambda aid: keys_of("shortcutKeys", aid)
def_keys = lambda aid: keys_of("defaultShortcutKeys", aid)

def set_keys(aid, keys):
    keys = [k for k in keys if k]
    args = [len(aid), *aid, len(keys)]
    for k in keys: args += [4, *k, *([0] * (4 - len(k)))]
    bus("setShortcutKeys", "asa(ai)u", *args, 6)

def owner(code):
    try: return bus("action", "i", code)
    except Exception: return []

def load_state():
    try: return json.load(open(STATE))
    except Exception: return {"touched": [], "steals": {}}

def save_state(st):
    if DRY: return
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    json.dump(st, open(STATE, "w"), indent=1, sort_keys=True)

def touch(st, comp, act):
    if [comp, act] not in st["touched"]: st["touched"].append([comp, act])

def read_binds():
    for line in sys.stdin:
        line = line.rstrip("\n")
        if not line or line.startswith("#"): continue
        comp, act, keys, *rest = line.split("\t")
        yield comp, act, [(parse(k),) for k in keys.split(";") if k], (rest[0] if rest else "set")

def apply():
    st = load_state()
    for comp, act, want, mode in read_binds():
        aid = action_id(comp, act)
        if comp.startswith("hyper-") and not DRY: bus("doRegister", "as", len(aid), *aid)
        for (code,) in want:  # free the key from any other action
            o = owner(code)
            if o and o[:2] != aid[:2]:
                print(f"  steal {name(code)} from {o[0]}/{o[1]}")
                if not DRY:
                    oid = list(o[:4]) if len(o) >= 4 else action_id(o[0], o[1])
                    set_keys(oid, [k for k in get_keys(oid) if k != (code,)])
                    touch(st, o[0], o[1]); st["steals"][name(code)] = f"{o[0]}/{o[1]}"
        cur = get_keys(aid)
        if mode == "set":  # keep non-Meta keys from current + defaults (e.g. Alt+F4)
            keep = [k for k in dict.fromkeys(cur + def_keys(aid)) if not k[0] & META]
            new = keep + [k for k in want if k not in keep]
        else:
            new = cur + [k for k in want if k not in cur]
        print(f"{comp}/{act}: {[name(k[0]) for k in cur]} -> {[name(k[0]) for k in new]}")
        if not DRY: set_keys(aid, new); touch(st, comp, act)
    save_state(st)

def check():
    bad = 0
    for comp, act, want, mode in read_binds():
        live = get_keys(action_id(comp, act))
        miss = [name(k[0]) for k in want if k not in live]
        if miss: bad += 1; print(f"DRIFT {comp}/{act}: missing {miss}")
    print(f"bindings out of sync: {bad}")
    st = load_state()
    print("keys taken from other actions:")
    for k, v in sorted(st["steals"].items()):
        try: o = owner(parse(k)); o = f"{o[0]}/{o[1]}" if o else ""
        except ValueError: o = ""
        if o != v: print(f"  {k:<18} was {v}")

def restore():
    st = load_state()
    for comp, act in st["touched"]:
        aid = action_id(comp, act)
        if comp.startswith("hyper-") or (comp == "kwin" and act.startswith("Hyper")):
            print(f"remove {comp}/{act}")
            if not DRY:
                set_keys(aid, [])
                try: bus("unregister", "ss", comp, act)
                except Exception: pass
        else:
            d = def_keys(aid)
            print(f"{comp}/{act} -> default {[name(k[0]) for k in d]}")
            if not DRY: set_keys(aid, d)

{"apply": apply, "check": check, "restore": restore}[sys.argv[1] if len(sys.argv) > 1 else "apply"]()
