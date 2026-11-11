#!/usr/bin/env python3
"""Write the translation catalog an extension ships: <ext_dir>/i18n/<lang>.json.

  extension-catalog.py <ext_dir> <po_file> [<lang>]

The strings are extracted from the extension's QML and manifest the same way scripts/trs.fish does
for the shell (xgettext, Tr.* keywords, scripts/manifest-strings.py) and looked up in <po_file>.
The JSON maps msgid (or "context\\u0004msgid") to its translation; Tr consults it when the shell's own
catalog has none (see Tr.qml extraCatalogs). Translations already in the JSON are kept when the .po
has none (an external extension's own strings are never in the shell's .po); strings no longer used
are dropped. Untranslated strings are listed on stderr. <lang> defaults to the .po file name.
"""
import json
import pathlib
import re
import subprocess
import sys
import tempfile

KEYWORDS = ["-ktr:1", "-ktrCtx:2c,1", "-ktrMarked:1", "-ktrN:1,2", "-ktrCtxN:4c,1,2", "-kmark:1", "-kmarkCtx:2c,1"]


def unquote(s: str) -> str:
    return json.loads(s)


def parse_po(text: str) -> list[tuple[str, str, str]]:
    """[(context, msgid, msgstr)] of the active (non-obsolete) entries; multi-line strings joined.
    For a plural entry msgstr is the list of its forms (msgstr[0], msgstr[1], …)."""
    out = []
    ctx = mid = mstr = None
    forms = None
    field = None

    def flush():
        if mid is not None:
            out.append((ctx or "", mid, forms if forms is not None else (mstr or "")))

    for raw in text.splitlines() + [""]:
        line = raw.strip()
        if not line:
            flush()
            ctx = mid = mstr = field = forms = None
            continue
        if line.startswith("#"):
            continue
        mp = re.match(r'^msgstr\[(\d+)\]\s+(".*")$', line)
        if mp:
            forms = forms or []
            forms.append(unquote(mp.group(2)))
            field = "form"
            continue
        if re.match(r'^msgid_plural\s', line):
            field = "plural"
            continue
        m = re.match(r'^(msgctxt|msgid|msgstr)\s+(".*")$', line)
        if m:
            field, val = m.group(1), unquote(m.group(2))
            if field == "msgctxt":
                ctx = val
            elif field == "msgid":
                mid = val
            else:
                mstr = val
        elif line.startswith('"') and field:
            val = unquote(line)
            if field == "msgctxt":
                ctx += val
            elif field == "msgid":
                mid += val
            elif field == "msgstr":
                mstr += val
            elif field == "form":
                forms[-1] += val
    return out


def main() -> None:
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    ext = pathlib.Path(sys.argv[1]).resolve()
    po = pathlib.Path(sys.argv[2])
    lang = sys.argv[3] if len(sys.argv) == 4 else po.stem
    here = pathlib.Path(__file__).resolve().parent

    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run([sys.executable, str(here / "manifest-strings.py"), tmp, str(ext.parent)], check=True)
        sources = sorted(str(p) for p in ext.rglob("*.qml"))
        manifest_js = pathlib.Path(tmp) / json.loads((ext / "manifest.json").read_text())["id"] / "manifest.json.js"
        sources.append(str(manifest_js))
        pot = pathlib.Path(tmp) / "ext.pot"
        subprocess.run(["xgettext", "-L", "JavaScript", "-o", str(pot), "--from-code=UTF-8", "--no-wrap", "-k", *KEYWORDS, *sources], check=True)
        wanted = [(c, m) for c, m, _ in parse_po(pot.read_text()) if m]

    translations = {(c, m): s for c, m, s in parse_po(po.read_text()) if m and s and (isinstance(s, str) or all(s))}
    out = ext / "i18n" / f"{lang}.json"
    try:
        existing = json.loads(out.read_text())
    except (OSError, ValueError):
        existing = {}
    catalog, missing = {}, []
    for c, m in wanted:
        key = f"{c}\u0004{m}" if c else m
        s = translations.get((c, m)) or existing.get(key)
        if s:
            catalog[key] = s
        else:
            missing.append(f"{c + ' | ' if c else ''}{m}")
    out.parent.mkdir(exist_ok=True)
    out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
    print(f"{out}: {len(catalog)} strings", file=sys.stderr)
    for m in missing:
        print(f"  untranslated: {m}", file=sys.stderr)


if __name__ == "__main__":
    main()
