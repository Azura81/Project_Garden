#!/usr/bin/env python3
"""
process_sprites.py
Konvertiert die 6 Gemini-Rohbilder (.jfif) aus raw_sprites/:
1. Entfernt per intelligenter Flood-Fill-Maskierung den weiÃŸen Hintergrund (beim Cockpit auch das Zentrum).
2. Entfernt eventuelle Sticker-Schlagschatten, wÃ¤hrend die weiÃŸe Papierkante und Tuschekontur sauber erhalten bleiben.
3. Schneidet leeren Raum ab und richtet den FuÃŸpunkt (StÃ¤ngel/FuÃŸ/Wurzeln) bÃ¼ndig an der Unterkante aus,
   damit die Figuren im 3D-Raum perfekt auf dem Boden stehen und nicht in der Luft schweben.
4. Skaliert mit hochwertigem Lanczos-Resampling auf die exakten ZielauflÃ¶sungen.
5. Speichert sie direkt als .png in den passenden Unterordnern von assets/sprites/.
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
        "mode": "sticker",
        "threshold": 195,
        "name": "Dornenrose (Rose Idle)"
    },
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r (1).jfif",
        "output": os.path.join(SPRITES_DIR, "plants", "golden_seedling.png"),
        "size": (1024, 1024),
        "mode": "aura",
        "threshold": 242,
        "name": "Goldener Keimling (Golden Seedling)"
    },
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r (2).jfif",
        "output": os.path.join(SPRITES_DIR, "plants", "dandelion_idle.png"),
        "size": (512, 512),
        "mode": "botanical",
        "threshold": 245,
        "name": "Pusteblume (Dandelion Idle)"
    },
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r (3).jfif",
        "output": os.path.join(SPRITES_DIR, "enemies", "snail_walk.png"),
        "size": (512, 512),
        "mode": "sticker",
        "threshold": 195,
        "name": "Gartenschnecke (Snail Walk)"
    },
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r (4).jfif",
        "output": os.path.join(SPRITES_DIR, "enemies", "beetle_walk.png"),
        "size": (512, 512),
        "mode": "sticker",
        "threshold": 195,
        "name": "SchmuckkÃ¤fer (Beetle Walk)"
    },
    {
        "file": "Gemini_Generated_Image_zh8r5xzh8r5xzh8r (5).jfif",
        "output": os.path.join(SPRITES_DIR, "cockpits", "rose_cockpit.png"),
        "size": (1920, 1080),
        "mode": "cockpit",
        "threshold": 225,
        "name": "Rosen-Cockpit 1st-Person (Rose Cockpit)"
    }
]

def process_sprite(config):
    input_path = os.path.join(RAW_DIR, config["file"])
    if not os.path.exists(input_path):
        print(f"FEHLER: Datei nicht gefunden: {input_path}")
        return False
        
    print(f"\n--- Verarbeite {config['name']} ---")
    print(f"Quelle: {config['file']}")
    
    img = Image.open(input_path).convert("RGB")
    arr = np.array(img)
    h, w = arr.shape[:2]
    
    mode = config["mode"]
    th = config["threshold"]
    
    if mode == "cockpit":
        is_bg = (arr[:, :, 0] >= th) & (arr[:, :, 1] >= th) & (arr[:, :, 2] >= th)
    elif mode == "aura":
        white_mask = (arr[:, :, 0] >= th) & (arr[:, :, 1] >= th) & (arr[:, :, 2] >= th)
        labeled, _ = label(white_mask)
        border_labels = set(np.unique(np.concatenate([
            labeled[0, :], labeled[-1, :], labeled[:, 0], labeled[:, -1]
        ])))
        border_labels.discard(0)
        is_bg = np.isin(labeled, list(border_labels))
    else:
        white_mask = (arr[:, :, 0] >= th) & (arr[:, :, 1] >= th) & (arr[:, :, 2] >= th)
        labeled, _ = label(white_mask)
        border_labels = set(np.unique(np.concatenate([
            labeled[0, :], labeled[-1, :], labeled[:, 0], labeled[:, -1]
        ])))
        border_labels.discard(0)
        is_bg = np.isin(labeled, list(border_labels))
        
    alpha = np.where(is_bg, 0, 255).astype(np.uint8)
    rgba = np.dstack([arr, alpha])
    rgba_img = Image.fromarray(rgba, mode="RGBA")
    
    target_w, target_h = config["size"]
    
    if mode == "cockpit":
        final_img = rgba_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    else:
        ys, xs = np.where(alpha > 10)
        if len(ys) > 0 and len(xs) > 0:
            min_x, max_x = xs.min(), xs.max()
            min_y, max_y = ys.min(), ys.max()
            cropped = rgba_img.crop((min_x, min_y, max_x + 1, max_y + 1))
            
            crop_w, crop_h = cropped.size
            scale = min((target_w * 0.94) / crop_w, (target_h * 0.94) / crop_h)
            new_w = max(1, int(crop_w * scale))
            new_h = max(1, int(crop_h * scale))
            scaled = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
            paste_x = (target_w - new_w) // 2
            bottom_margin = int(6 * (target_h / 512.0))
            paste_y = target_h - new_h - bottom_margin
            canvas.paste(scaled, (paste_x, paste_y), scaled)
            final_img = canvas
        else:
            final_img = rgba_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
            
    os.makedirs(os.path.dirname(config["output"]), exist_ok=True)
    final_img.save(config["output"], "PNG")
    print(f"Erfolgreich gespeichert ({target_w}x{target_h}, bodenbÃ¼ndig): {config['output']}")
    return True

def main():
    print("Starte Sprite-Import & BodenbÃ¼ndige Transparenz-Pipeline...")
    success_count = 0
    for cfg in SPRITE_CONFIGS:
        if process_sprite(cfg):
            success_count += 1
            
    print(f"\n==========================================")
    print(f"FERTIG: {success_count}/{len(SPRITE_CONFIGS)} Sprites erfolgreich konvertiert und abgelegt!")
    print(f"==========================================")

if __name__ == "__main__":
    main()
