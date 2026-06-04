"""从 assets/icon/app_icon.png 生成 Android mipmap/ic_launcher.png（各密度）。"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "icon" / "app_icon.png"
SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def main() -> None:
    img = Image.open(SRC).convert("RGBA")
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, size in SIZES.items():
        out = res / folder / "ic_launcher.png"
        img.resize((size, size), Image.Resampling.LANCZOS).save(out)
        print(f"wrote {out.relative_to(ROOT)} ({size}px)")


if __name__ == "__main__":
    main()
