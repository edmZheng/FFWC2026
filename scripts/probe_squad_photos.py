#!/usr/bin/env python3
"""Dry-run probe: try fetching photos for stratified sample of missing players.

Goal: validate hit rate honestly. First run revealed sampling bias —
the first 50 missing were all 2nd-tier Czech/Mexico/SA reserves.
This version samples N players each from top + tail football nations.
"""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fetch_squad_photos import fetch_thumbs, search_thumb, BATCH  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SQUADS = ROOT / "assets" / "data" / "squads.json"
PER_TEAM = 4
# Mix of football tiers: A-class (lots of wiki coverage) + lower-tier (sparse coverage)
PROBE_TEAMS = ["37", "33", "9", "45", "29", "17", "41", "21", "46", "25",
               "30", "28", "11", "40", "47"]


def main() -> None:
    payload = json.loads(SQUADS.read_text(encoding="utf-8"))
    squads = payload["squads"]
    sample: list[tuple[str, dict]] = []
    for tid in PROBE_TEAMS:
        miss = [p for p in squads.get(tid, []) if not p.get("photo_url")]
        for p in miss[:PER_TEAM]:
            sample.append((tid, p))
    names = [p["name_en"] for _, p in sample]
    print(f"probe sample: {len(sample)} players from {len(PROBE_TEAMS)} teams")

    direct_hit = 0
    search_hit = 0
    misses: list[tuple[str, str]] = []
    t0 = time.time()

    for i in range(0, len(names), BATCH):
        chunk = names[i : i + BATCH]
        thumbs = fetch_thumbs(chunk)
        for tid, p in sample[i : i + BATCH]:
            name = p["name_en"]
            url = thumbs.get(name.lower(), "")
            if url:
                direct_hit += 1
                continue
            url = search_thumb(name)
            time.sleep(0.8)
            if url:
                search_hit += 1
            else:
                misses.append((tid, name))
        print(
            f"  batch {i // BATCH + 1}: direct={direct_hit} search={search_hit} miss={len(misses)}"
        )

    dt = time.time() - t0
    total_hit = direct_hit + search_hit
    rate = total_hit / len(sample) if sample else 0
    print()
    print(f"=== PROBE RESULT ({dt:.1f}s) ===")
    print(f"direct hit  : {direct_hit}/{len(sample)}")
    print(f"search hit  : {search_hit}/{len(sample)}")
    print(f"total hit   : {total_hit}/{len(sample)}  ({rate*100:.1f}%)")
    print(f"missed      : {len(misses)}")
    if misses:
        print("--- sample misses ---")
        for tid, n in misses[:20]:
            print(f"  team={tid}  {n}")
    if sample:
        per_player = dt / len(sample)
        all_missing = sum(
            1 for ps in squads.values() for p in ps if not p.get("photo_url")
        )
        est_min = (per_player * all_missing) / 60
        print(f"\nestimated full-run wall time: ~{est_min:.1f} min "
              f"(@ {per_player:.2f}s/player, {all_missing} missing)")
        print(f"projected full-run hits: ~{int(all_missing * rate)} / {all_missing}")


if __name__ == "__main__":
    main()
