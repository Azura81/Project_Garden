#!/usr/bin/env python3
"""
process_sprites.py
Konvertiert alle 6 Rohbilder (.jfif) aus raw_sprites/:
1. rose_idle: Globales Color-Keying für helle, ungesättigte Weißtöne -> alle eingeschlossenen weißen Flächen zwischen Stängeln und Blättern werden transparent.
2. dandelion_idle: Saubere Freistellung der Pusteblumen-Kugeln oben & globales Freistellen der Lücken zwischen den Rosettenblättern unten.
3. golden_seedling: Entfernung des gezackten hellen Halos, 25% kleiner skaliert und bodenbündig ausgerichtet.
4. snail_walk & beetle_walk: Sticker-Kontur ohne äußeren Schlagschatten, bodenbündig ausgerichtet.
5. rose_cockpit: Bildschirm-Overlay 1920x1080 mit transparenter Mitte und Außenkanten.
"""

import os
import sys
from PIL import Image
import numpy as np
from scipy.ndimage import label

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RAW_DIR = os.path.join(BASE_DIR, "raw_sprites")
if not os.path.exists(RAW_DIR):
    RAW_DIR = os.path.join(BASE_DIR, "assets", "raw sprites")

SPRITES_DIR = os.path.join(BASE_DIR, "assets", "sprites")

SPRITE_CONFIGS = [
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r.jfif",
        "output": os.path.join(SPRITES_DIR, "plants", "rose_idle.png"),
        "size": (512, 512),
        "mode": "rose_color_key",
        "name": "Dornenrose (Rose Idle)"
    },
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r (1).jfif",
        "output": os.path.join(SPRITES_DIR, "plants", "golden_seedling.png"),
        "size": (1024, 1024),
        "mode": "seedling_aura",
        "name": "Goldener Keimling (Golden Seedling)"
    },
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r (2).jfif",
        "output": os.path.join(SPRITES_DIR, "plants", "dandelion_idle.png"),
        "size": (512, 512),
        "mode": "dandelion_hybrid",
        "name": "Pusteblume (Dandelion Idle)"
    },
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r (3).jfif",
        "output": os.path.join(SPRITES_DIR, "enemies", "snail_walk.png"),
        "size": (512, 512),
        "mode": "sticker_flood",
        "name": "Gartenschnecke (Snail Walk)"
    },
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r (4).jfif",
        "output": os.path.join(SPRITES_DIR, "enemies", "beetle_walk.png"),
        "size": (512, 512),
        "mode": "sticker_flood",
        "name": "Schmuckkäfer (Beetle Walk)"
    },
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r (5).jfif",
        "output": os.path.join(SPRITES_DIR, "cockpits", "rose_cockpit.png"),
        "size": (1920, 1080),
        "mode": "cockpit",
        "name": "Rosen-Cockpit 1st-Person (Rose Cockpit)"
    }
]

def process_sprite(config):
    input_path = os.path.join(RAW_DIR, config["file"])
    if not os.path.exists(input_path):
        print(f"FEHLER: Datei nicht gefunden: {input_path}")
        return False
        
    print(f"\n--- Verarbeite {config['name']} ---")
    img = Image.open(input_path).convert("RGB")
    arr = np.array(img)
    h, w = arr.shape[:2]
    mode = config["mode"]
    
    r_chan = arr[:, :, 0].astype(int)
    g_chan = arr[:, :, 1].astype(int)
    b_chan = arr[:, :, 2].astype(int)
    min_rgb = np.minimum(np.minimum(r_chan, g_chan), b_chan)
    max_rgb = np.maximum(np.maximum(r_chan, g_chan), b_chan)
    diff_rgb = max_rgb - min_rgb
    
    if mode == "rose_color_key":
        # Globales Color-Keying für helle, ungesättigte Weißtöne
        # Rose hat nur sattes Rot, Pflanzengrün, Astbraun -> kein helles ungesättigtes Weiß im Motiv
        is_bg = (min_rgb >= 200) & (diff_rgb <= 28)
        
    elif mode == "seedling_aura":
        # Goldener Keimling: Papierhintergrund ist ungesättigtes Weiß (diff < 18)
        # Die magische Aura & Funken haben goldenes Gelb (diff >= 18, hohes R & G, tieferes B)
        is_bg = (min_rgb >= 200) & (diff_rgb < 18)
        
    elif mode == "dandelion_hybrid":
        # Pusteblume:
        # A. Flood-Fill von den Bildrändern für den Gesamthintergrund
        white_mask = (r_chan >= 242) & (g_chan >= 242) & (b_chan >= 242)
        labeled, _ = label(white_mask)
        border_labels = set(np.unique(np.concatenate([
            labeled[0, :], labeled[-1, :], labeled[:, 0], labeled[:, -1]
        ])))
        border_labels.discard(0)
        is_bg = np.isin(labeled, list(border_labels))
        
        # B. Für den unteren Bereich (Rosettenblätter und Stängel, y >= 800):
        # Alle eingeschlossenen weißen Flächen zwischen den Blättern entfernen
        is_lower_white = (min_rgb >= 205) & (diff_rgb <= 28)
        is_bg[800:, :] = is_bg[800:, :] | is_lower_white[800:, :]
        
    elif mode == "sticker_flood":
        # Sticker (Schnecke & Käfer): Flood-Fill von außen mit Schattenschnitt
        white_mask = (r_chan >= 195) & (g_chan >= 195) & (b_chan >= 195)
        labeled, _ = label(white_mask)
        border_labels = set(np.unique(np.concatenate([
            labeled[0, :], labeled[-1, :], labeled[:, 0], labeled[:, -1]
        ])))
        border_labels.discard(0)
        is_bg = np.isin(labeled, list(border_labels))
        
    elif mode == "cockpit":
        # Cockpit: Zentrum und Randtaschen transparent
        is_bg = (r_chan >= 225) & (g_chan >= 225) & (b_chan >= 225)
        
    else:
        is_bg = min_rgb >= 245

    # Alpha-Kanal erzeugen
    alpha = np.where(is_bg, 0, 255).astype(np.uint8)
    rgba = np.dstack([arr, alpha])
    rgba_img = Image.fromarray(rgba, mode="RGBA")
    target_w, target_h = config["size"]
    
    if mode == "cockpit":
        final_img = rgba_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    else:
        # Bounding-Box sichtbarer Pixel ermitteln
        ys, xs = np.where(alpha > 10)
        if len(ys) > 0 and len(xs) > 0:
            min_x, max_x = xs.min(), xs.max()
            min_y, max_y = ys.min(), ys.max()
            cropped = rgba_img.crop((min_x, min_y, max_x + 1, max_y + 1))
            
            crop_w, crop_h = cropped.size
            
            # Für den Goldenen Keimling ca. 25% kleiner skalieren
            fill_ratio = 0.75 if mode == "seedling_aura" else 0.94
            scale = min((target_w * fill_ratio) / crop_w, (target_h * fill_ratio) / crop_h)
            new_w = max(1, int(crop_w * scale))
            new_h = max(1, int(crop_h * scale))
            scaled = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
            paste_x = (target_w - new_w) // 2
            # Exakt bodenbündig an die Unterkante platzieren
            paste_y = target_h - new_h - 2
            canvas.paste(scaled, (paste_x, paste_y), scaled)
            final_img = canvas
        else:
            final_img = rgba_img.resize((target_w, target_h), Image.Resampling.LANCZOS)

    os.makedirs(os.path.dirname(config["output"]), exist_ok=True)
    final_img.save(config["output"], "PNG")
    print(f"Erfolgreich gespeichert ({target_w}x{target_h}): {config['output']}")
    return True

def main():
    print("Starte Sprite-Freistellung mit Alpha-Masken & Color-Keying...")
    for cfg in SPRITE_CONFIGS:
        process_sprite(cfg)
    print("\nAlle Sprites erfolgreich verarbeitet!")

if __name__ == "__main__":
    main()
