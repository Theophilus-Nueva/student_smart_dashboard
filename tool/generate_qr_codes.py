"""Generate the printable AR Guide checkpoint QR codes (Week 7).

One QR code per key campus location. Each code holds only the checkpoint ID
(UC001...UC006); the app looks the ID up in lib/models/tour.dart
(campusLocations) and shows that location's information when it scans it.

Usage (needs the `segno` and `pillow` Python packages):
    python3 tool/generate_qr_codes.py
Writes docs/qr_codes/UC00x_<name>.png (one sign per location) and
docs/qr_codes/all_checkpoints_A4.png (all six on one A4 page).
Keep the list below in sync with campusLocations.
"""

import io
from pathlib import Path

import segno
from PIL import Image, ImageDraw, ImageFont

LOCATIONS = [
    ("UC001", "Main Building", "Administration and classrooms"),
    ("UC002", "Library", "Learning and Research Center"),
    ("UC003", "Registrar", "Records and enrolment"),
    ("UC004", "Computer Laboratory", "COECSA laboratories"),
    ("UC005", "Student Center", "Student services and organisations"),
    ("UC006", "Audio Visual Theater", "Seminars, talks and screenings"),
]

BRAND = (183, 28, 28)  # #B71C1C
OUT = Path(__file__).resolve().parent.parent / "docs" / "qr_codes"
FONTS = Path("/System/Library/Fonts/Supplemental")


def font(size, bold=False):
    name = "Arial Bold.ttf" if bold else "Arial.ttf"
    try:
        return ImageFont.truetype(str(FONTS / name), size)
    except OSError:
        return ImageFont.load_default(size)


def centered(draw, y, text, f, fill, width):
    w = draw.textlength(text, font=f)
    draw.text(((width - w) / 2, y), text, font=f, fill=fill)


def sign(code, title, subtitle, width=1200):
    """A printable sign: red header, the QR code, location name and ID."""
    qr = segno.make(code, error="h")
    # 4-module quiet zone (white border) is required for reliable scanning.
    buf = io.BytesIO()
    qr.save(buf, kind="png", scale=26, border=4)
    buf.seek(0)
    qr_img = Image.open(buf).convert("RGB")
    height = 300 + qr_img.height + 330
    img = Image.new("RGB", (width, height), "white")
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, width, 220], fill=BRAND)
    centered(d, 48, "LPU Cavite · Smart Campus Tour Guide", font(44), "white", width)
    centered(d, 118, "AR Guide Checkpoint", font(64, True), "white", width)
    img.paste(qr_img, ((width - qr_img.width) // 2, 260))
    y = 260 + qr_img.height + 30
    centered(d, y, title, font(84, True), "black", width)
    centered(d, y + 105, subtitle, font(44), (90, 90, 90), width)
    centered(d, y + 175, f"Checkpoint {code}", font(48, True), BRAND, width)
    centered(d, y + 245, "Open the app's AR Guide and point the camera here",
             font(36), (90, 90, 90), width)
    d.rectangle([0, 0, width - 1, height - 1], outline=(200, 200, 200), width=4)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    signs = []
    for code, title, subtitle in LOCATIONS:
        img = sign(code, title, subtitle)
        slug = title.lower().replace(" ", "_")
        img.save(OUT / f"{code}_{slug}.png", dpi=(300, 300))
        signs.append(img)

    # A4 at 300 dpi: 2 columns x 3 rows, cut along the grey borders.
    page_w, page_h, margin = 2480, 3508, 90
    cell_w = (page_w - margin * 3) // 2
    cell_h = (page_h - margin * 4) // 3
    page = Image.new("RGB", (page_w, page_h), "white")
    for i, img in enumerate(signs):
        scale = min(cell_w / img.width, cell_h / img.height)
        small = img.resize((int(img.width * scale), int(img.height * scale)),
                           Image.LANCZOS)
        col, row = i % 2, i // 2
        x = margin + col * (cell_w + margin) + (cell_w - small.width) // 2
        y = margin + row * (cell_h + margin) + (cell_h - small.height) // 2
        page.paste(small, (x, y))
    page.save(OUT / "all_checkpoints_A4.png", dpi=(300, 300))
    print(f"Wrote {len(signs)} signs and the A4 sheet to {OUT}")


if __name__ == "__main__":
    main()
