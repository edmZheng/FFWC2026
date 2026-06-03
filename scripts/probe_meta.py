#!/usr/bin/env python3
"""Probe combined photo+zh fetch on stratified sample (no disk write)."""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fetch_squad_meta import fetch_meta, search_meta, BATCH  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SQUADS = ROOT / "assets" / "data" / "squads.json"
PER_TEAM = 3
PROBE_TEAMS = ["37", "33", "9", "45", "29", "41", "17", "21", "46", "47", "30"]


def main() -> None:
    payload = json.loads(SQUADS.read_text(encoding="utf-8"))
    squads = payload["squads"]
    sample: list[dict] = []
    for tid in PROBE_TEAMS:
        miss = [p for p in squads.get(tid, []) if not p.get("photo_url")]
        for p in miss[:PER_TEAM]:
            sample.append({"team": tid, "p": p})
    names = [s["p"]["name_en"] for s in sample]
    print(f"probe: {len(sample)} players from {len(PROBE_TEAMS)} teams")

    photo_hit = 0
    zh_hit = 0
    samples_zh: list[tuple[str, str, str]] = []
    t0 = time.time()

    for i in range(0, len(names), BATCH):
        chunk = names[i : i + BATCH]
        meta = fetch_meta(chunk)
        for s in sample[i : i + BATCH]:
            name = s["p"]["name_en"]
            m = meta.get(name.lower())
            if not m or (not m.get("thumb") and not m.get("zh")):
                m = search_meta(name)
                time.sleep(0.5)
            if m.get("thumb"):
                photo_hit += 1
            if m.get("zh"):
                zh_hit += 1
                samples_zh.append((s["team"], name, m["zh"]))
        print(f"  batch {i // BATCH + 1}: photo={photo_hit} zh={zh_hit}")

    dt = time.time() - t0
    print(f"\n=== {dt:.1f}s ===")
    print(f"photo hit : {photo_hit}/{len(sample)} ({photo_hit*100/len(sample):.0f}%)")
    print(f"zh    hit : {zh_hit}/{len(sample)} ({zh_hit*100/len(sample):.0f}%)")
    print("\n--- sample zh names (team, en, zh) ---")
    for t, en, zh in samples_zh[:25]:
        print(f"  team={t}  {en}  →  {zh}")


if __name__ == "__main__":
    main()
