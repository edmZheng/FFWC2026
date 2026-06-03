#!/usr/bin/env python3
"""Batch-fetch Wikipedia player portraits into squads.json (resumable)."""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQUADS = ROOT / "assets" / "data" / "squads.json"
UA = "FFWC-Tracker/1.0 (batch-photos; contact: dev@local)"
BATCH = 20
DELAY = 2.5


def fetch_thumbs(names: list[str], retries: int = 4) -> dict[str, str]:
    if not names:
        return {}
    titles = "|".join(n.replace(" ", "_") for n in names)
    url = (
        "https://en.wikipedia.org/w/api.php?action=query&format=json"
        f"&titles={urllib.parse.quote(titles, safe='')}"
        "&prop=pageimages&pithumbsize=400&redirects=1"
    )
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            out: dict[str, str] = {}
            for page in data.get("query", {}).get("pages", {}).values():
                title = page.get("title", "").replace("_", " ")
                thumb = page.get("thumbnail", {}).get("source", "")
                if title and thumb:
                    out[title.lower()] = thumb
            return out
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < retries - 1:
                wait = 30 * (attempt + 1)
                print(f"429 wait {wait}s...", flush=True)
                time.sleep(wait)
                continue
            raise
    return {}


def search_thumb(name: str) -> str:
    """Fallback: search then load pageimage."""
    q = urllib.parse.quote(name)
    url = (
        "https://en.wikipedia.org/w/api.php?action=query&format=json"
        f"&list=search&srsearch={q}%20footballer&srlimit=1"
    )
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        hits = data.get("query", {}).get("search", [])
        if not hits:
            return ""
        title = hits[0]["title"]
        return fetch_thumbs([title]).get(title.lower(), "")
    except Exception:
        return ""


def main() -> None:
    payload = json.loads(SQUADS.read_text(encoding="utf-8"))
    squads = payload["squads"]
    all_players = [p for ps in squads.values() for p in ps]
    need = [p for p in all_players if not p.get("photo_url")]
    names = [p["name_en"] for p in need]
    print(f"need photos: {len(names)}", flush=True)

    for i in range(0, len(names), BATCH):
        chunk = names[i : i + BATCH]
        thumbs = fetch_thumbs(chunk)
        for p in need[i : i + BATCH]:
            url = thumbs.get(p["name_en"].lower(), "")
            if not url:
                url = search_thumb(p["name_en"])
                time.sleep(0.8)
            p["photo_url"] = url
        matched = sum(1 for p in all_players if p.get("photo_url"))
        payload["photo_source"] = "Wikimedia Commons via Wikipedia API"
        SQUADS.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print(
            f"batch {i // BATCH + 1}/{(len(names) + BATCH - 1) // BATCH} "
            f"total_with_photo={matched}/{len(all_players)}",
            flush=True,
        )
        time.sleep(DELAY)

    matched = sum(1 for p in all_players if p.get("photo_url"))
    print(f"done matched {matched}/{len(all_players)}")


if __name__ == "__main__":
    main()
