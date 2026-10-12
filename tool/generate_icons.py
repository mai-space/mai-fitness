"""Erzeugt das App-Icon (Android, iOS) aus einer Vorlage.

    pip install cairosvg pillow && python3 tool/generate_icons.py

Motiv: weiße Hantel, leicht schräg, auf dem orangen Markenverlauf — gleiche
Bildsprache wie die anderen Mai-Apps.
"""

import io
import json
from pathlib import Path

import cairosvg

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"

SEED = "#C4511F"
ACCENT = "#EE8A4F"

# 108×108 = Android-Adaptive-Icon-Raster; Motiv bleibt in der 66er-Schutzzone.
DUMBBELL = """
  <g transform="rotate(-35 54 54)" fill="{c}">
    <rect x="34" y="50.5" width="40" height="7" rx="3.5"/>
    <rect x="30" y="37" width="10" height="34" rx="4"/>
    <rect x="68" y="37" width="10" height="34" rx="4"/>
    <rect x="23" y="43" width="8" height="22" rx="3.5"/>
    <rect x="77" y="43" width="8" height="22" rx="3.5"/>
  </g>
"""
BACKGROUND = f"""
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{ACCENT}"/>
      <stop offset="1" stop-color="{SEED}"/>
    </linearGradient>
  </defs>
"""


def svg(body, view="0 0 108 108"):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}">{body}</svg>'
    )


MOTIF = DUMBBELL.format(c="#fff")
FOREGROUND = svg(MOTIF)
# Volles Bild (Legacy-Icon): abgerundetes Quadrat + Motiv.
ROUNDED = svg(
    BACKGROUND
    + '<rect x="14" y="14" width="80" height="80" rx="20" fill="url(#bg)"/>'
    + MOTIF,
    view="14 14 80 80",
)
# iOS: vollflächig, engerer Ausschnitt (keine 66er-Schutzzone nötig).
IOS = svg(
    BACKGROUND + '<rect width="108" height="108" fill="url(#bg)"/>' + MOTIF,
    view="20 20 68 68",
)


def png(source, path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(
        bytestring=source.encode(),
        write_to=str(path),
        output_width=size,
        output_height=size,
    )


def ios_icons():
    """iOS-AppIcon ohne Alphakanal (App Store lehnt Transparenz ab)."""
    from PIL import Image

    folder = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((folder / "Contents.json").read_text())
    for image in contents["images"]:
        name = image.get("filename")
        if not name:
            continue
        points = float(image["size"].split("x")[0])
        size = round(points * int(image["scale"].rstrip("x")))
        data = cairosvg.svg2png(
            bytestring=IOS.encode(), output_width=size, output_height=size
        )
        rgba = Image.open(io.BytesIO(data)).convert("RGBA")
        flat = Image.new("RGB", rgba.size, SEED)
        flat.paste(rgba, mask=rgba.split()[3])
        flat.save(folder / name, optimize=True)


def play_store_icon():
    """Play-Store-Symbol 512 × 512, vollflächig (Google rundet selbst ab)."""
    source = svg(
        BACKGROUND + '<rect width="108" height="108" fill="url(#bg)"/>' + MOTIF,
        view="14 14 80 80",
    )
    png(source, ROOT / "store/android/icon_512.png", 512)


def main():
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, factor in densities.items():
        folder = RES / f"mipmap-{name}"
        png(ROUNDED, folder / "ic_launcher.png", round(48 * factor))
        png(FOREGROUND, folder / "ic_launcher_foreground.png", round(108 * factor))
        # Themed Icons (Android 13+) nutzen nur Alpha: die Hantel selbst.
        png(FOREGROUND, folder / "ic_launcher_monochrome.png", round(108 * factor))
    ios_icons()
    play_store_icon()


if __name__ == "__main__":
    main()
