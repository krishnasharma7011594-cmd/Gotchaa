import math
try:
    from PIL import Image, ImageDraw, ImageFont  # type: ignore
except ImportError:
    import sys
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'Pillow'])
    from PIL import Image, ImageDraw, ImageFont  # type: ignore


def make_circle_logo(size, filename):
    """Generate a circular logo with gradient background and white G letter."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Gradient colors: purple -> teal
    r1, g1, b1 = 155, 111, 216   # purple #9B6FD8
    r2, g2, b2 = 39, 196, 178    # teal   #27C4B2

    cx, cy = size // 2, size // 2
    radius = size // 2

    # Draw circle pixel-by-pixel with gradient
    for y in range(size):
        for x in range(size):
            dist = math.hypot(x - cx, y - cy)
            if dist <= radius:
                # Diagonal gradient factor
                factor = (x + y) / (2.0 * size)
                cr = int(r1 * (1 - factor) + r2 * factor)
                cg = int(g1 * (1 - factor) + g2 * factor)
                cb = int(b1 * (1 - factor) + b2 * factor)

                # Anti-aliasing at the edge
                if dist > radius - 1.5:
                    alpha = int(255 * (radius - dist) / 1.5)
                    alpha = max(0, min(255, alpha))
                else:
                    alpha = 255

                d.point((x, y), fill=(cr, cg, cb, alpha))

    # Draw the "G" letter
    font_size = int(size * 0.58)
    font = None
    for font_name in ["arialbd.ttf", "Arial Bold.ttf", "arial.ttf", "DejaVuSans-Bold.ttf"]:
        try:
            font = ImageFont.truetype(font_name, font_size)
            break
        except Exception:
            continue
    if font is None:
        font = ImageFont.load_default()

    text = "G"
    # Get text bounding box
    left, top, right, bottom = d.textbbox((0, 0), text, font=font)
    w = right - left
    h = bottom - top
    # Center the text, nudge slightly left and up for optical centering
    tx = (size - w) / 2 - left - size * 0.01
    ty = (size - h) / 2 - top - size * 0.04
    d.text((tx, ty), text, fill="white", font=font)

    img.save(filename)
    print(f"Saved: {filename}")


def make_splash_screen(size, filename):
    """Generate splash screen: dark background with centered circular logo."""
    # Dark background (near-black with purple tint)
    bg_color = (13, 13, 26, 255)   # #0D0D1A
    img = Image.new('RGBA', (size, size), bg_color)

    # Create circle logo at 45% of splash size
    logo_size = int(size * 0.45)
    logo = Image.new('RGBA', (logo_size, logo_size), (0, 0, 0, 0))
    d = ImageDraw.Draw(logo)

    r1, g1, b1 = 155, 111, 216
    r2, g2, b2 = 39, 196, 178
    cx, cy = logo_size // 2, logo_size // 2
    radius = logo_size // 2

    for y in range(logo_size):
        for x in range(logo_size):
            dist = math.hypot(x - cx, y - cy)
            if dist <= radius:
                factor = (x + y) / (2.0 * logo_size)
                cr = int(r1 * (1 - factor) + r2 * factor)
                cg = int(g1 * (1 - factor) + g2 * factor)
                cb = int(b1 * (1 - factor) + b2 * factor)
                if dist > radius - 1.5:
                    alpha = int(255 * (radius - dist) / 1.5)
                    alpha = max(0, min(255, alpha))
                else:
                    alpha = 255
                d.point((x, y), fill=(cr, cg, cb, alpha))

    # Draw G inside the logo
    font_size = int(logo_size * 0.58)
    font = None
    for font_name in ["arialbd.ttf", "Arial Bold.ttf", "arial.ttf", "DejaVuSans-Bold.ttf"]:
        try:
            font = ImageFont.truetype(font_name, font_size)
            break
        except Exception:
            continue
    if font is None:
        font = ImageFont.load_default()

    text = "G"
    left, top, right, bottom = d.textbbox((0, 0), text, font=font)
    w = right - left
    h = bottom - top
    tx = (logo_size - w) / 2 - left - logo_size * 0.01
    ty = (logo_size - h) / 2 - top - logo_size * 0.04
    d.text((tx, ty), text, fill="white", font=font)

    # Paste logo centered on dark background
    offset = (size - logo_size) // 2
    img.alpha_composite(logo, (offset, offset))

    # Save as PNG (RGBA)
    img.save(filename)
    print(f"Saved: {filename}")


# Generate assets
make_circle_logo(1024, "c:/Gotchaa/assets/logo/gotcha_icon.png")
make_circle_logo(1024, "c:/Gotchaa/assets/logo/gotcha_icon_circle.png")
make_splash_screen(1024, "c:/Gotchaa/assets/logo/gotcha_splash.png")

print("\nAll assets generated successfully!")
print("Next steps:")
print("  flutter pub run flutter_launcher_icons")
print("  flutter pub run flutter_native_splash:create")
