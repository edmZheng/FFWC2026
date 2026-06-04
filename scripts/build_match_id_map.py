#!/usr/bin/env python3
"""Build worldcup26.ir.id → highlightly.matchId mapping.

Join logic: same kickoff date (YYYY-MM-DD) AND same {home,away} team-name set
(unordered, normalized). worldcup26.ir uses MM/DD/YYYY HH:MM local Eastern;
highlightly uses ISO 8601 in UTC (date-only match handles the tz shift fine
since group-stage WC matches are sparse).
"""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "data" / "match_id_map.json"
WORKER = "https://ffwc-proxy.randomdre13.workers.dev/matches"
W26 = "https://worldcup26.ir/get/games"

NAME_ALIASES = {
    "usa": "united states",
    "us": "united states",
    "south korea": "korea republic",
    "korea republic": "korea republic",
    "republic of ireland": "ireland",
    "ivory coast": "côte d'ivoire",
    "cote d'ivoire": "côte d'ivoire",
    "côte d'ivoire": "côte d'ivoire",
    "dr congo": "congo dr",
    "democratic republic of the congo": "congo dr",
    "cape verde": "cabo verde",
    "czech republic": "czechia",
    "czechia": "czechia",
    "bosnia and herzegovina": "bosnia",
    "bosnia & herzegovina": "bosnia",
}


def norm(name: str) -> str:
    s = name.strip().lower()
    return NAME_ALIASES.get(s, s)


def _get(url: str) -> dict:
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "FFWC-Tracker/1.0 (build_match_id_map.py)",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))


def parse_w26_date(s: str) -> str:
    # "06/11/2026 13:00" → "2026-06-11"
    if not s:
        return ""
    parts = s.split(" ")[0].split("/")
    if len(parts) != 3:
        return ""
    mm, dd, yyyy = parts
    return f"{yyyy}-{mm.zfill(2)}-{dd.zfill(2)}"


def parse_hl_date(s: str) -> str:
    # "06/11/2026 19:00:00" or "2026-06-11T19:00:00Z" — handle both
    if not s:
        return ""
    if "T" in s:
        return s.split("T")[0]
    parts = s.split(" ")[0].split("/")
    if len(parts) != 3:
        return ""
    mm, dd, yyyy = parts
    return f"{yyyy}-{mm.zfill(2)}-{dd.zfill(2)}"


def main() -> None:
    print("fetching worldcup26.ir...")
    w26 = _get(W26).get("games", [])
    print(f"  {len(w26)} games")

    print("fetching highlightly via Worker...")
    hl = _get(WORKER).get("data", [])
    print(f"  {len(hl)} matches")

    # Index highlightly by (date, frozenset({homeNorm, awayNorm}))
    hl_index: dict[tuple, dict] = {}
    for m in hl:
        d = parse_hl_date(m.get("date", ""))
        h = norm(m.get("homeTeam", {}).get("name", ""))
        a = norm(m.get("awayTeam", {}).get("name", ""))
        if not d or not h or not a:
            continue
        hl_index[(d, frozenset({h, a}))] = m

    def shift_day(d: str, days: int) -> str:
        from datetime import date as Date, timedelta
        y, m, dd = map(int, d.split("-"))
        return (Date(y, m, dd) + timedelta(days=days)).isoformat()

    def to_iso_utc(s: str) -> str:
        """Normalize highlightly date to ISO 8601 UTC: '2026-06-11T19:00:00Z'."""
        if not s:
            return ""
        if "T" in s:
            return s if s.endswith("Z") else s + "Z"
        # "06/11/2026 19:00:00" or "06/11/2026 19:00"
        parts = s.split(" ")
        if len(parts) < 2:
            return ""
        mdy = parts[0].split("/")
        hms = parts[1].split(":")
        if len(mdy) != 3 or len(hms) < 2:
            return ""
        mm, dd, yyyy = mdy
        hh = hms[0]
        mn = hms[1]
        ss = hms[2] if len(hms) > 2 else "00"
        return f"{yyyy}-{mm.zfill(2)}-{dd.zfill(2)}T{hh.zfill(2)}:{mn.zfill(2)}:{ss.zfill(2)}Z"

    mapping: dict[str, dict] = {}
    unmatched: list[dict] = []
    for g in w26:
        wid = str(g.get("id", ""))
        d = parse_w26_date(g.get("local_date", ""))
        h = norm(g.get("home_team_name_en", ""))
        a = norm(g.get("away_team_name_en", ""))
        if not wid or not d or not h or not a:
            unmatched.append(g)
            continue
        teams = frozenset({h, a})
        # Try same day, +1, -1 to absorb venue-local → UTC date shift
        match = (
            hl_index.get((d, teams))
            or hl_index.get((shift_day(d, 1), teams))
            or hl_index.get((shift_day(d, -1), teams))
        )
        if match:
            mapping[wid] = {
                "hl": match["id"],
                "utc": to_iso_utc(match.get("date", "")),
            }
        else:
            unmatched.append({"id": wid, "date": d, "home": h, "away": a})

    payload = {
        "source": "worldcup26.ir × highlightly.net",
        "generated": "2026-06-04",
        "worldcup26_to_highlightly": mapping,
        "note": "Keys = worldcup26.ir game id; values = {hl: highlightly match id, utc: ISO 8601 kickoff UTC}",
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nmapped {len(mapping)}/{len(w26)} matches")
    print(f"wrote {OUT}")
    print(f"\nunmatched ({len(unmatched)}):")
    for u in unmatched[:20]:
        print(f"  {u}")


if __name__ == "__main__":
    main()
