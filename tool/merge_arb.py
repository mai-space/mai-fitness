"""Fügt lib/l10n/parts/*.<lang>.json zu lib/l10n/app_<lang>.arb zusammen.

Jede Teildatei: {"key": "Text", "@key": {...Metadaten...}}. Doppelte
Schlüssel brechen ab.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PARTS = ROOT / "lib/l10n/parts"

for lang in ("de", "en"):
    merged = {"@@locale": lang}
    owner = {}
    for part in sorted(PARTS.glob(f"*.{lang}.json")):
        for key, value in json.loads(part.read_text(encoding="utf-8")).items():
            if key in merged:
                raise SystemExit(f"{key} doppelt: {owner[key]} und {part.name}")
            merged[key] = value
            owner[key] = part.name
    (ROOT / f"lib/l10n/app_{lang}.arb").write_text(
        json.dumps(merged, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(lang, len([k for k in merged if not k.startswith("@")]), "Texte")
