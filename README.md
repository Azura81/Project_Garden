# Petal & Thorn 🌸 – Botanisches 3D Mobile Tower Defense

Ein 3D-Tower-Defense-Spiel für Mobile (Android & iOS) und PC in **Godot 4**, das klassische Vogelperspektiven-Strategie mit direkter **1st-Person-Symbiose-Steuerung** verbindet.

---

## 🌿 Highlights & Alleinstellungsmerkmale (USP)

* **Dual-Perspektiven-Gameplay:**
  * **Taktik-Modus (Vogelperspektive):** Diorama-Blick auf das Gartenbeet. Drag-Schwenken, Pinch-Zooming, Wassertropfen-Management und Ausbau von Verteidigungspflanzen.
  * **Symbiose-Modus (1st-Person):** Per Klick auf eine aufgewertete Blüte fliegt die Kamera in **0,4 Sekunden sanft in das Innere der Blüte** (inkl. 1 Sekunde Orientierungs-Zeitlupe). Der Spieler zielt manuell, erhält **+25 % Extra-Tautropfen** und feuert gezielt auf Schwachstellen.
* **Aquarell- & Natur-Ästhetik:** Sanfte Pastelltöne, handgezeichneter Watercolor-Shader und subtile Papierstruktur.
* **Hybrid-Ökonomie:** Tautropfen (In-Match-Währung für Pflanzen, Gießen und Symbiose) sowie Goldene Samenkörner (dauerhafte Meta-Progression im Gärtner-Buch).

---

## 📁 Projektstruktur

```
res://
├── assets/
│   ├── shaders/          # Aquarell- & Papier-Textur-Shader (watercolor.gdshader, paper_texture.gdshader)
│   ├── models/           # 3D-Modelle & Props
│   └── ui/               # Icons & Ring-Menü-Grafiken
├── scenes/
│   ├── main/             # Hauptmenü (MainMenu.tscn)
│   ├── levels/           # Level-Szenen (Level_01.tscn mit Path3D, TowerSpots & GoldenCore)
│   ├── towers/           # TowerBase.tscn, ThornRose.tscn
│   ├── enemies/          # EnemyBase.tscn, GardenSnail.tscn
│   └── ui/               # HUD_Tactical.tscn, HUD_FirstPerson.tscn, RadialMenu.tscn
└── scripts/
    ├── autoload/         # GameManager.gd (Tautropfen, Wellen, Kern-HP), SaveManager.gd
    ├── camera/           # CameraRig.gd (Tweening & 1st-Person-Zielen)
    ├── components/       # HealthComponent.gd, HitboxComponent.gd, WeakspotComponent.gd
    ├── levels/           # LevelBase.gd, TowerSpot.gd
    ├── towers/           # TowerBase.gd, ThornRose.gd
    └── ui/               # HUDTactical.gd, HUDFirstPerson.gd, RadialMenu.gd
```

---

## 🎮 Steuerung & Prototyp-Ablauf

1. **Starten:** `Level_01.tscn` in Godot 4 öffnen und starten (`F5` oder `F6`).
2. **Pflanzen setzen:** Auf einen der Erd-Pflanzplätze (`TowerSpot`) klicken, um das Ring-Menü zu öffnen und eine **Dornen-Rose (50💧)** zu pflanzen.
3. **Aufwerten & Symbiose:**
   * Pflanze anklicken $\rightarrow$ **Gießen (Stufe 2)** für 75💧.
   * Anschließend **Symbiose freischalten** für 100💧.
   * **In die Blüte schlüpfen**: Kamera zoomt in die 1st-Person-Sicht. Maus bewegen zum Zielen, Spezialfähigkeit testen, mit „Aussteigen“ zurückkehren.
4. **Welle starten:** Unten auf **„Welle starten 🌻“** tippen. Schädlinge laufen entlang des Pfads zum Goldenen Kern.

---

## 🛠️ Technische Voraussetzungen

* **Engine:** Godot Engine 4.3+ / 4.7+ (Mobile Renderer)
* **Auflösung:** 1920 × 1080 (Landscape, Stretch: `canvas_items`, Aspect: `expand`)
* **Sprache:** GDScript
