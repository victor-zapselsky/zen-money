"""
Generate app icon and splash images with a dollar sign ($) on the app's
primary color (#433DCB). Run with: python tool/generate_icon.py
"""
from PIL import Image, ImageDraw, ImageFont
import os, math

PRIMARY  = (0x43, 0x3D, 0xCB)   # #433DCB — app primary color
WHITE    = (255, 255, 255, 255)
TRANSP   = (0,   0,   0,   0)

ICON_SIZE   = 1024
SPLASH_SIZE = 512

# ─── helpers ──────────────────────────────────────────────────────────────────

def get_font(size):
    """Try system fonts; fall back to default."""
    candidates = [
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/calibrib.ttf",
        "C:/Windows/Fonts/segoeui.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def draw_centered_text(draw, text, font, canvas_size, fill):
    """Draw text centred on a square canvas."""
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (canvas_size - tw) // 2 - bbox[0]
    y = (canvas_size - th) // 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=fill)


def make_round_bg(size, color_rgb):
    """Solid rounded-square image (Android adaptive icon bg)."""
    img  = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    r    = size // 8
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=r,
                            fill=color_rgb + (255,))
    return img


# ─── app_icon.png  (full icon, purple bg + $ symbol) ─────────────────────────

def make_app_icon():
    img  = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), PRIMARY + (255,))
    draw = ImageDraw.Draw(img)
    font = get_font(int(ICON_SIZE * 0.58))
    draw_centered_text(draw, "$", font, ICON_SIZE, WHITE)
    return img.convert("RGB")


# ─── app_icon_fg.png  (adaptive foreground — transparent bg, white $) ────────

def make_icon_fg():
    """
    The adaptive foreground should be a 108dp "safe zone" inside a 108dp image,
    but in practice Flutter Launcher Icons expects a full square PNG.
    We leave transparent padding so the $ sits in the safe 72dp area (~67%).
    """
    size  = ICON_SIZE
    img   = Image.new("RGBA", (size, size), TRANSP)
    draw  = ImageDraw.Draw(img)
    # Use ~40 % of the image so the symbol is safely inside the safe zone
    font  = get_font(int(size * 0.42))
    draw_centered_text(draw, "$", font, size, WHITE)
    return img


# ─── app_splash.png  (launch screen centre image on white/grey bg) ────────────

def make_splash():
    size  = SPLASH_SIZE
    img   = Image.new("RGBA", (size, size), TRANSP)
    draw  = ImageDraw.Draw(img)
    # Circle background with primary colour
    margin = size // 8
    draw.ellipse([margin, margin, size - margin, size - margin],
                 fill=PRIMARY + (255,))
    # White $ symbol
    font = get_font(int(size * 0.52))
    draw_centered_text(draw, "$", font, size, WHITE)
    return img


# ─── main ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    out = "assets/icon"
    os.makedirs(out, exist_ok=True)

    icon = make_app_icon()
    icon.save(f"{out}/app_icon.png")
    print(f"  OK  {out}/app_icon.png  ({ICON_SIZE}x{ICON_SIZE})")

    fg = make_icon_fg()
    fg.save(f"{out}/app_icon_fg.png")
    print(f"  OK  {out}/app_icon_fg.png  ({ICON_SIZE}x{ICON_SIZE}, transparent)")

    splash = make_splash()
    splash.save(f"{out}/app_splash.png")
    print(f"  OK  {out}/app_splash.png  ({SPLASH_SIZE}x{SPLASH_SIZE})")

    print("\nDone. Now run:")
    print("  flutter pub run flutter_launcher_icons")
    print("  flutter pub run flutter_native_splash:create")
