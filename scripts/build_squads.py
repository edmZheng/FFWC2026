#!/usr/bin/env python3
"""Parse 2026 FIFA World Cup squads from Wikipedia export and fetch player photos."""

from __future__ import annotations

import json
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI_MD = ROOT / "scripts" / "2026_squads_wiki.md"
OUT_JSON = ROOT / "assets" / "data" / "squads.json"
TEAMS_JSON = ROOT / "assets" / "data" / "teams.json"

UA = "FFWC-Tracker/1.0 (squads-builder; contact: dev@local)"

# Wikipedia section title -> app team id
WIKI_TO_ID = {
    "Czech Republic": "4",
    "Mexico": "1",
    "South Africa": "2",
    "South Korea": "3",
    "Bosnia and Herzegovina": "6",
    "Canada": "5",
    "Qatar": "7",
    "Switzerland": "8",
    "Brazil": "9",
    "Haiti": "11",
    "Morocco": "10",
    "Scotland": "12",
    "Australia": "15",
    "Paraguay": "14",
    "Turkey": "16",
    "United States": "13",
    "Curaçao": "18",
    "Ecuador": "20",
    "Germany": "17",
    "Ivory Coast": "19",
    "Japan": "22",
    "Netherlands": "21",
    "Sweden": "23",
    "Tunisia": "24",
    "Belgium": "25",
    "Egypt": "26",
    "Iran": "27",
    "New Zealand": "28",
    "Cape Verde": "30",
    "Saudi Arabia": "31",
    "Spain": "29",
    "Uruguay": "32",
    "France": "33",
    "Iraq": "35",
    "Norway": "36",
    "Senegal": "34",
    "Algeria": "38",
    "Argentina": "37",
    "Austria": "39",
    "Jordan": "40",
    "Colombia": "44",
    "DR Congo": "42",
    "Portugal": "41",
    "Uzbekistan": "43",
    "Croatia": "46",
    "England": "45",
    "Ghana": "47",
    "Panama": "48",
}

POS_ZH = {"GK": "门将", "DF": "后卫", "MF": "中场", "FW": "前锋"}

ROW_RE = re.compile(
    r"^\|\s*(\d+)\s*\|\s*\d+\s+(GK|DF|MF|FW)\s*\|\s*([^|]+?)\s*\|",
    re.IGNORECASE,
)


def fetch_json(url: str, delay: float = 0.35) -> dict:
    time.sleep(delay)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def wiki_photo(name: str, cache: dict[str, str | None]) -> str | None:
    key = name.strip().lower()
    if key in cache:
        return cache[key]
    title = urllib.parse.quote(name.replace(" ", "_"))
    url = (
        "https://en.wikipedia.org/w/api.php?action=query&format=json"
        f"&titles={title}&prop=pageimages&pithumbsize=400&redirects=1"
    )
    try:
        data = fetch_json(url, delay=0.4)
        pages = data.get("query", {}).get("pages", {})
        thumb = None
        for page in pages.values():
            thumb = page.get("thumbnail", {}).get("source")
            if thumb:
                break
        cache[key] = thumb
        return thumb
    except Exception:
        cache[key] = None
        return None


def clean_name(raw: str) -> tuple[str, bool]:
    s = raw.strip()
    captain = "(captain)" in s.lower()
    s = re.sub(r"\(captain\)", "", s, flags=re.IGNORECASE).strip()
    return s, captain


def parse_squads(text: str) -> dict[str, list[dict]]:
    squads: dict[str, list[dict]] = {}
    current_team: str | None = None

    for line in text.splitlines():
        if line.startswith("### "):
            title = line[4:].strip()
            current_team = title if title in WIKI_TO_ID else None
            continue
        if not current_team:
            continue
        m = ROW_RE.match(line)
        if not m:
            continue
        number = int(m.group(1))
        pos = m.group(2).upper()
        name, is_captain = clean_name(m.group(3))
        team_id = WIKI_TO_ID[current_team]
        squads.setdefault(team_id, []).append(
            {
                "number": number,
                "name_en": name,
                "position": pos,
                "position_zh": POS_ZH.get(pos, pos),
                "captain": is_captain,
            }
        )
    return squads


def load_existing_meta() -> dict[str, dict]:
    """保留 squads.json 里已有的 photo_url 和 name_zh，避免重跑脚本时丢失。"""
    if not OUT_JSON.exists():
        return {}
    try:
        data = json.loads(OUT_JSON.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}
    out: dict[str, dict] = {}
    for ps in data.get("squads", {}).values():
        for p in ps:
            key = p["name_en"].strip().lower()
            url = (p.get("photo_url") or "").strip()
            zh = (p.get("name_zh") or "").strip()
            if url or zh:
                out[key] = {"photo_url": url, "name_zh": zh}
    return out


def main() -> None:
    if not WIKI_MD.exists():
        raise SystemExit(f"Missing {WIKI_MD}")

    text = WIKI_MD.read_text(encoding="utf-8")
    squads = parse_squads(text)
    preserved = load_existing_meta()
    photo_cache: dict[str, str | None] = {
        k: v["photo_url"] for k, v in preserved.items() if v["photo_url"]
    }
    if preserved:
        print(f"preserved {len(preserved)} existing meta record(s)", flush=True)
    total = sum(len(v) for v in squads.values())
    done = 0

    for team_id, players in squads.items():
        for p in players:
            done += 1
            key = p["name_en"].strip().lower()
            prev = preserved.get(key, {})
            if prev.get("photo_url"):
                p["photo_url"] = prev["photo_url"]
            else:
                photo = wiki_photo(p["name_en"], photo_cache)
                p["photo_url"] = photo or ""
            if prev.get("name_zh"):
                p["name_zh"] = prev["name_zh"]
            else:
                p["name_zh"] = ""
            if done % 20 == 0:
                print(f"photos {done}/{total}...", flush=True)

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "source": "Wikipedia 2026 FIFA World Cup squads + Wikimedia player portraits",
        "photo_source": "Wikimedia Commons via Wikipedia API",
        "updated": "2026-06-03",
        "squads": squads,
    }
    OUT_JSON.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    with_photo = sum(
        1 for ps in squads.values() for p in ps if p.get("photo_url")
    )
    print(f"teams={len(squads)} players={total} with_photo={with_photo}")
    print(f"wrote {OUT_JSON}")


if __name__ == "__main__":
    main()
