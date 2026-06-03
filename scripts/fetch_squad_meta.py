#!/usr/bin/env python3
"""Combined Wikipedia fetcher: photo + Chinese name in ONE API call per batch.

Why combined: separate runs would burn 2x the API budget against Wikipedia
and we already saw 429 throttling on the photo-only path. langlinks share
the same query.

For every player without photo_url OR name_zh:
  - batch query (pageimages + langlinks zh) for up to BATCH names
  - fallback: per-player Wikipedia search "<name> footballer"
  - on success, the langlinks "to" field is the Chinese title

Resumable: writes squads.json after every batch. Won't overwrite existing fields.
"""

from __future__ import annotations

import gzip
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from opencc import OpenCC

_TRAD2SIMP = OpenCC("t2s")
# Strip parenthesized disambiguation tails — Wikipedia adds (足球員) (消歧義) etc.
_DISAMBIG_RE = re.compile(r"\s*[（(][^)）]*[)）]\s*$")


def normalize_zh(title: str) -> str:
    if not title:
        return ""
    s = _DISAMBIG_RE.sub("", title).strip()
    return _TRAD2SIMP.convert(s) if s else ""

ROOT = Path(__file__).resolve().parents[1]
SQUADS = ROOT / "assets" / "data" / "squads.json"
# More compliant UA: real-looking project + email-shaped contact reduces
# server-side risk flags vs "dev@local".
UA = (
    "FFWC-Tracker/1.0 (https://github.com/edmZheng/worldcup_tracker; "
    "wc26tracker@gmail.com) Python-urllib/3.14"
)
BATCH = 30
DELAY = 1.8


def _http_get(url: str, timeout: int = 60) -> dict:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": UA,
            "Accept": "application/json",
            "Accept-Encoding": "gzip",
            "Api-User-Agent": UA,
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read()
        if resp.headers.get("Content-Encoding") == "gzip":
            raw = gzip.decompress(raw)
        return json.loads(raw.decode("utf-8"))


def fetch_meta(names: list[str], retries: int = 4) -> dict[str, dict]:
    """Returns: { name_lower: {"thumb": url|"", "zh": title|""} }"""
    if not names:
        return {}
    titles = "|".join(n.replace(" ", "_") for n in names)
    url = (
        "https://en.wikipedia.org/w/api.php?action=query&format=json"
        f"&titles={urllib.parse.quote(titles, safe='')}"
        "&prop=pageimages|langlinks&pithumbsize=400&lllang=zh&lllimit=50"
        "&redirects=1&formatversion=2"
    )
    for attempt in range(retries):
        try:
            data = _http_get(url, timeout=90)
            out: dict[str, dict] = {}
            for page in data.get("query", {}).get("pages", []):
                title = page.get("title", "").replace("_", " ")
                if not title:
                    continue
                thumb = page.get("thumbnail", {}).get("source", "")
                zh_raw = ""
                for ll in page.get("langlinks", []) or []:
                    if ll.get("lang") == "zh":
                        zh_raw = ll.get("title", "")
                        break
                out[title.lower()] = {"thumb": thumb, "zh": normalize_zh(zh_raw)}
            return out
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < retries - 1:
                wait = 20 * (attempt + 1)
                print(f"  429 wait {wait}s...", flush=True)
                time.sleep(wait)
                continue
            raise
        except (urllib.error.URLError, TimeoutError) as e:
            if attempt < retries - 1:
                wait = 5 * (attempt + 1)
                print(f"  net {e!r} retry {wait}s...", flush=True)
                time.sleep(wait)
                continue
            raise
    return {}


def search_meta(name: str) -> dict:
    """Fallback: search Wikipedia then re-query the top hit for meta."""
    q = urllib.parse.quote(f"{name} footballer")
    url = (
        "https://en.wikipedia.org/w/api.php?action=query&format=json"
        f"&list=search&srsearch={q}&srlimit=1"
    )
    try:
        data = _http_get(url, timeout=30)
        hits = data.get("query", {}).get("search", [])
        if not hits:
            return {"thumb": "", "zh": ""}
        title = hits[0]["title"]
        meta = fetch_meta([title])
        return meta.get(title.lower(), {"thumb": "", "zh": ""})
    except Exception:
        return {"thumb": "", "zh": ""}


def main() -> None:
    payload = json.loads(SQUADS.read_text(encoding="utf-8"))
    squads = payload["squads"]
    all_players: list[dict] = []
    for ps in squads.values():
        all_players.extend(ps)

    # Pending = missing EITHER photo OR name_zh
    pending = [
        p for p in all_players
        if not p.get("photo_url") or not p.get("name_zh")
    ]
    names = [p["name_en"] for p in pending]
    print(f"players total={len(all_players)} pending={len(names)}", flush=True)

    direct_hit = search_hit = miss = 0
    t0 = time.time()

    for i in range(0, len(names), BATCH):
        chunk = names[i : i + BATCH]
        meta = fetch_meta(chunk)
        for p in pending[i : i + BATCH]:
            m = meta.get(p["name_en"].lower())
            if not m:
                m = search_meta(p["name_en"])
                time.sleep(0.6)
                if m.get("thumb") or m.get("zh"):
                    search_hit += 1
                else:
                    miss += 1
            else:
                if m.get("thumb") or m.get("zh"):
                    direct_hit += 1
                else:
                    miss += 1
            # Only fill empty fields; never overwrite existing
            if m.get("thumb") and not p.get("photo_url"):
                p["photo_url"] = m["thumb"]
            if m.get("zh") and not p.get("name_zh"):
                p["name_zh"] = m["zh"]

        # write back per batch (resumable)
        with_photo = sum(1 for q in all_players if q.get("photo_url"))
        with_zh = sum(1 for q in all_players if q.get("name_zh"))
        payload["photo_source"] = "Wikimedia Commons via Wikipedia API"
        payload["name_zh_source"] = "Wikipedia EN→ZH langlinks"
        SQUADS.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        batches_total = (len(names) + BATCH - 1) // BATCH
        elapsed = time.time() - t0
        print(
            f"batch {i // BATCH + 1}/{batches_total}  "
            f"direct={direct_hit} search={search_hit} miss={miss}  "
            f"with_photo={with_photo}/{len(all_players)}  "
            f"with_zh={with_zh}/{len(all_players)}  "
            f"({elapsed:.0f}s)",
            flush=True,
        )
        time.sleep(DELAY)

    with_photo = sum(1 for q in all_players if q.get("photo_url"))
    with_zh = sum(1 for q in all_players if q.get("name_zh"))
    print(
        f"\ndone: with_photo={with_photo}/{len(all_players)}  "
        f"with_zh={with_zh}/{len(all_players)}"
    )


if __name__ == "__main__":
    main()
