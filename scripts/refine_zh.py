#!/usr/bin/env python3
"""Refine name_zh in squads.json:

Layer 1: manual override dict (zh_overrides.OVERRIDES) — by English name.
Layer 2: re-render existing zh title via zh.wikipedia.org
         &action=parse&prop=displaytitle&variant=zh-cn — fixes the cases
         where Wikipedia has a zh-cn conversion dictionary entry for the
         Hong Kong / Taiwan transliteration (e.g. 朗拿度→罗纳尔多).

Inputs are read from / written back to assets/data/squads.json.
Run repeatedly; idempotent and resumable per batch.
"""

from __future__ import annotations

import gzip
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from zh_overrides import OVERRIDES  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SQUADS = ROOT / "assets" / "data" / "squads.json"
UA = (
    "FFWC-Tracker/1.0 (https://github.com/edmZheng/worldcup_tracker; "
    "wc26tracker@gmail.com) Python-urllib/3.14"
)
DELAY = 0.6
WRITE_EVERY = 25
_HTML_TAG = re.compile(r"<[^>]+>")


def _http_get(url: str, timeout: int = 30) -> dict:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": UA,
            "Accept": "application/json",
            "Accept-Encoding": "gzip",
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read()
        if resp.headers.get("Content-Encoding") == "gzip":
            raw = gzip.decompress(raw)
        return json.loads(raw.decode("utf-8"))


def variant_zh_cn(title: str, retries: int = 3) -> str:
    """Returns zh-cn rendered displaytitle, or "" if page missing/no conv."""
    if not title:
        return ""
    page = urllib.parse.quote(title.replace(" ", "_"))
    url = (
        "https://zh.wikipedia.org/w/api.php?action=parse&format=json"
        f"&page={page}&prop=displaytitle&variant=zh-cn&redirects=1"
    )
    for attempt in range(retries):
        try:
            data = _http_get(url)
            dt = data.get("parse", {}).get("displaytitle", "")
            return _HTML_TAG.sub("", dt) if dt else ""
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return ""
            if e.code == 429 and attempt < retries - 1:
                wait = 15 * (attempt + 1)
                print(f"  429 wait {wait}s...", flush=True)
                time.sleep(wait)
                continue
            return ""
        except Exception:
            if attempt < retries - 1:
                time.sleep(3)
                continue
            return ""
    return ""


def main() -> None:
    payload = json.loads(SQUADS.read_text(encoding="utf-8"))
    squads = payload["squads"]
    all_players = [p for ps in squads.values() for p in ps]

    override_hits = 0
    variant_hits = 0
    kept = 0
    skipped_empty = 0
    diffs: list[tuple[str, str, str, str]] = []

    pending_with_zh = [p for p in all_players if (p.get("name_zh") or "").strip()]
    print(
        f"players={len(all_players)}  with name_zh={len(pending_with_zh)}  "
        f"overrides={len(OVERRIDES)}",
        flush=True,
    )
    t0 = time.time()
    processed = 0

    for p in all_players:
        en = p.get("name_en", "").strip()
        old = (p.get("name_zh") or "").strip()
        new = old

        if en in OVERRIDES:
            new = OVERRIDES[en]
            if new != old:
                override_hits += 1
                diffs.append(("override", en, old or "(empty)", new))
            else:
                # already matched override; count as override but no diff
                override_hits += 1
        elif old:
            rendered = variant_zh_cn(old)
            time.sleep(DELAY)
            if rendered and rendered != old:
                new = rendered
                variant_hits += 1
                diffs.append(("variant", en, old, new))
            else:
                kept += 1
        else:
            skipped_empty += 1

        p["name_zh"] = new
        processed += 1

        if processed % WRITE_EVERY == 0:
            payload["name_zh_refined"] = "2026-06-04"
            SQUADS.write_text(
                json.dumps(payload, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            elapsed = time.time() - t0
            print(
                f"  {processed}/{len(all_players)}  "
                f"override={override_hits}  variant={variant_hits}  "
                f"kept={kept}  empty={skipped_empty}  ({elapsed:.0f}s)",
                flush=True,
            )

    # Final write
    payload["name_zh_refined"] = "2026-06-04"
    SQUADS.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(
        f"\nDONE: override={override_hits}  variant={variant_hits}  "
        f"kept={kept}  empty={skipped_empty}"
    )
    print("\n--- sample diffs (first 30) ---")
    for src, en, old, new in diffs[:30]:
        print(f"  [{src}] {en:25s}  {old}  →  {new}")


if __name__ == "__main__":
    main()
