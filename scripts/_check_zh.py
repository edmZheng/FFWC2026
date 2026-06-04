import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
data = json.loads((ROOT / "assets/data/squads.json").read_text(encoding="utf-8"))
checks = [
    ("41", "Cristiano Ronaldo"),
    ("41", "Bernardo Silva"),
    ("41", "Bruno Fernandes"),
    ("41", "Diogo Costa"),
    ("9", "Vinícius Júnior"),
    ("9", "Casemiro"),
    ("9", "Marquinhos"),
    ("9", "Alex Sandro"),
    ("37", "Lionel Messi"),
    ("37", "Lautaro Martínez"),
    ("33", "Kylian Mbappé"),
    ("33", "Antoine Griezmann"),
    ("45", "Harry Kane"),
    ("45", "Jude Bellingham"),
    ("29", "Lamine Yamal"),
    ("29", "Rodri"),
    ("17", "Florian Wirtz"),
    ("17", "Jamal Musiala"),
    ("21", "Memphis Depay"),
    ("21", "Frenkie de Jong"),
]
for tid, name in checks:
    found = next((p for p in data["squads"].get(tid, []) if p["name_en"] == name), None)
    if found:
        zh = found.get("name_zh") or "(empty)"
        print(f"  {name:28s} -> {zh}")
    else:
        print(f"  {name:28s} -> NOT IN SQUAD")
