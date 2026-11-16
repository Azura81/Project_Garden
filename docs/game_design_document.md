# Game Design Document (GDD) – Botanisches 1st-Person Tower Defense (Arbeitstitel: *Petal & Thorn*)

> **VERBINDLICHE SYSTEM-ANWEISUNG FÜR ANTIGRAVITY (KI-ENTWICKLUNGSAGENT):**
> 1. **Projekt-Kontext:** Dieses Dokument definiert die vollständige Spielvision, Mechanik, Architektur und den Grafikstil für ein Mobile-3D-Tower-Defense-Spiel in **Godot 4 (GDScript)**. Nutze es als verbindliche Referenz für Code-Struktur, UI-Layouts, Kamera-Systeme und Balancing-Werte.
> 2. **Tool- & Programm-Verbindung (Sofortiger Erstschritt):** Verbinde dich selbstständig mit allen wichtigen Programmen und Schnittstellen für dieses Projekt (insbesondere **Godot 4 Engine / CLI**, **Dateisystem des Projektordners**, **Git** für Versionskontrolle sowie falls vorhanden **Android SDK / Export-Templates** oder **MCP-Server für Godot**).
> 3. **Voraussetzungen abfragen:** Prüfe als allererstes deine aktuelle Umgebung und **teile dem Nutzer klar und strukturiert mit, was du noch benötigst**, um direkt auf Godot 4 zugreifen, Szenen erstellen, das Spiel starten und Fehler-Logs auslesen zu können (z. B. den Installationspfad der `godot.exe` / Godot-Binary, den Pfad zum Projektordner, aktivierte Editor-Plugins/MCP-Verbindungen oder fehlende Export-Templates). Warte auf diese Angaben bzw. richte alles ein, bevor du mit dem eigentlichen Programmieren beginnst.

## 1. High-Level Konzept & Plattform

* **Genre:** 3D Action-Tower-Defense (Strategie + 1st-Person-Geschütz-Steuerung)

* **Zielplattform:** Mobile (Android & iOS), **reines Querformat (Landscape, 16:9 / 19.5:9)**

* **Engine & Renderer:** Godot 4.x mit dem **Mobile-Renderer** (optimiert für Smartphone-GPUs)

* **Alleinstellungsmerkmal (USP):** Klassisches Tower Defense trifft auf direkte 1st-Person-Steuerung. Jede Verteidigungspflanze besitzt ein spezielles Upgrade (**„Symbiose-Blüte“**), mit dem der Spieler direkt in die Blüte schlüpft und die Pflanze aus der Ego-Perspektive steuert, während die übrigen Pflanzen weiter automatisch kämpfen.

## 2. Visueller Stil & Atmosphäre

* **Art-Style:** Handgezeichneter **Aquarell-Look (Watercolor)** mit sanften Pastell- und Naturfarben, weichen Farbverläufen, leichter Papier-Textur im Hintergrund/UI und dezenten Outlines.

* **Perspektive & Maßstab:**

  * *Taktik-Modus (Standard):* Leicht geneigte Vogelperspektive (Diorama-Blick auf ein Gartenbeet).

  * *Symbiose-Modus (1st-Person):* Perspektive aus der Mitte der jeweiligen Pflanzenblüte. Durch den Maßstabswechsel wirken Grashalme wie Bäume und Schnecken/Käfer wie imposante Gegner.

## 3. Kern-Gameplay & Spielablauf (Core Loop)

1. **Planungsphase (Unbegrenzte Zeit vor Welle 1):**

   * Der Spieler sieht das Beet, die festen Pflanzplätze, den Pfad und rote Markierungen am Rand (Anzeige der kommenden Gegner-Richtungen).

   * Mit dem **Startbudget an Tautropfen** werden erste Pflanzen gesetzt. Start der Welle erfolgt manuell durch Tippen auf „Welle starten“.

2. **Kampf- & Gieß-Phase (Wellen 1 bis N):**

   * Schädlinge laufen entlang definierter Pfade (`Path3D`) Richtung **Goldener Kern**.

   * Besiegte Gegner lassen **Tautropfen** fallen.

   * Der Spieler tippt auf Pflanzplätze, um neue Pflanzen zu setzen oder bestehende durch **„Gießen“** (Tautropfen ausgeben) aufzuwerten.

3. **Symbiose-Phase (1st-Person-Eingriff):**

   * Ab Stufe 2 kann für jede Pflanze das **Symbiose-Upgrade** freigeschaltet werden.

   * Ein Tippen auf das Symbiose-Icon über der Pflanze löst einen **0,4-sekündigen weichen Kameraflug** in die Blüte aus (inkl. 1 Sekunde leichter Zeitlupe beim Einstieg zur Orientierung).

   * In der 1st-Person-Ansicht steuert der Spieler das Zielen manuell, erhält **+25 % / +1–2 Extra-Tautropfen** pro Abschuss und kann gezielt Schwachstellen von Bossen oder Luftgegner (Vögel) treffen.

   * Begrenzt durch eine **Überhitzungs-/Energieanzeige** (ca. 15–20 Sek. aktive Steuerung), danach automatische Rückkehr in die Vogelperspektive (oder jederzeit manuell über den „Aussteigen“-Button).

4. **Rundenende & Progression:**

   * Wird der Goldene Kern verteidigt, wächst er am Ende des Levels sichtbar ein Stück weiter (Keimling $\rightarrow$ Sprössling $\rightarrow$ Knospe $\rightarrow$ Blüte).

   * Belohnung: **1 bis 3 Goldene Samenkörner** (abhängig von den verbleibenden Lebenspunkten des Kerns) für dauerhafte Verbesserungen im *Gärtner-Buch*.

## 4. Mobile Touch-Steuerung & HUD (Querformat)

### Taktik-Modus (Vogelperspektive)

* **Kamera:** Leichtes Schwenken (1-Finger-Drag) und Zoomen (Pinch-to-Zoom) innerhalb fester Beet-Grenzen.

* **Interaktion:** Tippen auf einen freien oder belegten **Pflanzplatz** öffnet ein **Ring-Menü (Radial Menu)** direkt um den Spot (Pflanzen bauen, Gießen/Upgraden, Symbiose freischalten, Verkaufen).

* **HUD:**

  * Oben links: Tautropfen-Anzeige, Lebenspunkte des Goldenen Kerns.

  * Oben rechts: Aktuelle Welle (z. B. `Welle 2/4`), Spielgeschwindigkeit (`1x` / `2x`), Pause-Button.

### 1st-Person-Modus (Symbiose-Steuerung)

* **Linke Bildschirmhälfte (Zielen):** Virtuelles Touchpad ohne feste Position (1-Finger-Drag schwenkt die Blüte weich horizontal & vertikal). Inklusive **magnetischem Aim-Assist** (leichte Verlangsamung nahe an Gegnern).

* **Rechte Bildschirmhälfte (Feuern & Spezialfähigkeit):**

  * *Standard (Auto-Fire):* Automatische Schussabgabe, sobald ein Gegner im Fadenkreuz liegt (oder bei gedrücktem Finger).

  * *Spezial-Button (Unten rechts):* Löst die individuelle Pflanzen-Fähigkeit aus (mit Cooldown-Ring).

* **Bildschirmmitte (Fadenkreuz):** Kreisförmiger Balken direkt um das Fadenkreuz zeigt **Symbiose-Energie / Überhitzung** an.

* **Oben links:** Gut erreichbarer **„Aussteigen“-Button** (sofortiger Rückflug in die Vogelperspektive) + **Gefahren-Indikator** (roter Pfeil am Rand, falls auf einem anderen Pfad Gegner durchbrechen).

## 5. Pflanzen-System & Hybrid-Auswahl

### Auswahl-System (Hybrid aus *Kingdom Rush* & *Plants vs. Zombies*)

* **Welt 1 (Levels 1–12):** Spieler schaltet schrittweise **5 Kern-Pflanzen** frei. Alle 5 sind jederzeit im Ring-Menü verfügbar (optimaler Einstieg ohne Deck-Zwang).

* **Ab Welt 2 (ab Level 13):** Einführung des **Samen-Decks (5 Plätze)**. Vor Levelbeginn wählt der Spieler aus seiner Sammlung 5 Samentütchen passend zur Gegner-Vorschau aus.

### Die 5 Kern-Pflanzen (Welt 1)

| Pflanze | Rolle (TD-Modus) | 1st-Person-Upgrade („Symbiose“) | Spezialfähigkeit (Rechts) | 
| ----- | ----- | ----- | ----- | 
| **1. Dornen-Rose** | Schnellfeuer-Schütze (Dornen) gegen Einzelziele | **Dornensturm:** Hohe Feuerrate; kontinuierliche Treffer erhöhen die Schussfrequenz. | **Duftwolke:** Betäubt und verlangsamt nahe Schnecken kurzzeitig. | 
| **2. Löwenzahn** | Flächen-Mörser (Samen-Bomben im Bogen) | **Pusteblumen-Artillerie:** Erhöhte Sicht; Zielkreis per Drag verschieben & loslassen für Samen-Regen. | **Windstoß:** Feuert sofort eine breite Salve Flugsamen über den Pfad. | 
| **3. Brennnessel** | Nahkampf-Peitsche / hoher Schaden gegen Tanks | **Giftstachel-Scharfschütze:** Markiert leuchtende Schwachstellen an gepanzerten Käfern (300 % Krit-Schaden). | **Wurzel-Fessel:** Ranken halten einen großen Gegner für 3 Sek. fest. | 
| **4. Minze** *(Kraut)* | Passiver Support: Kühlt Nachbarpflanzen | **Frost-Atem:** Verschießt einen kühlenden Eisnebel-Strahl auf kurze Distanz. *(Verlängert Symbiose-Zeit von Nachbarn).* | **Kälteschock:** Friert Gegner im Umkreis kurz ein. | 
| **5. Lavendel** *(Kraut)* | Passiver Support: Verlangsamt Gegner im Radius | **Schlafpollen-Werfer:** Schießt beruhigende Pollenwolken, die Gegner stark ausbremsen. | **Tiefschlaf:** Lässt eine Gegnergruppe für 2,5 Sek. einschlafen. | 

## 6. Gegner-Typen (Schädlinge)

1. **Blattlaus (Schwarm):** Sehr klein, schnell, wenig HP, kommt in großen Gruppen. (5 Tropfen)

2. **Gartenschnecke (Standard):** Langsam, mittlere HP. Im 1st-Person-Modus zurückdrängbar durch Treffer auf die Fühler. (10 Tropfen)

3. **Hirschkäfer / Maikäfer (Gepanzerter Tank):** Harter Chitin-Panzer vorne (blockt frontalen Schaden). Schwachstelle am Rücken/Hinterleib – leicht treffbar durch kluge Pflanzen-Positionierung und 1st-Person-Zielen. (30 Tropfen)

4. **Spatz / Krähe (Luft-Gegner):** Fliegt direkt über Hindernisse hinweg zum Goldenen Kern. Automatische Pflanzen treffen schlecht; im 1st-Person-Modus gezielt vom Himmel holbar. (35 Tropfen)

5. **Welt-Boss (Level 12, z. B. Riesen-Maulwurf / Käfer-König):** Mehrere Schwachstellen, erfordert Wechseln zwischen verschiedenen Pflanzen.

## 7. Wirtschaft & Balancing-Richtwerte (Tautropfen)

* **Startbudget (Level 1):** `150 Tautropfen` (reicht für 3 Basis-Pflanzen à 50 Tropfen).

* **Kosten-Beispiel (Dornen-Rose):**

  * Einpflanzen (Stufe 1): `50 Tropfen`

  * Gießen auf Stufe 2: `75 Tropfen`

  * **Symbiose-Upgrade (1st-Person freischalten):** `100 Tropfen` (verfügbar ab Stufe 2)

  * Gießen auf Stufe 3 (Meisterblüte): `140 Tropfen`

* **Meta-Progression (Gärtner-Buch):** Goldene Samenkörner (1–3 pro Level) schalten dauerhafte Boni frei (z. B. *+15 Start-Tautropfen*, *-10 % Symbiose-Kosten*, *+20 % Kern-HP*).

## 8. Level-Struktur: Welt 1 – „Das Gartenbeet“ (12 Levels)

* **Feste Pflanzplätze (`TowerSpot`):** Jedes Level besteht aus einem 3D-Beet mit vordefinierten Erd-Spots für saubere Sichtlinien im 1st-Person-Modus.

* **Lernkurve:**

  * **Levels 1–3 (Hochbeet):** 1 Pfad, Einführung Rose, Schnecken, Gießen & Symbiose-Upgrade.

  * **Levels 4–6 (Erdbeerbeet):** 2 Pfade um Hindernisse, Einführung Löwenzahn & gepanzerte Käfer.

  * **Levels 7–9 (Kräuterbeet):** Terrassen/Höhenunterschiede (Vorteil im 1st-Person-Modus!), Einführung Vögel & Support-Kräuter (Minze/Lavendel).

  * **Levels 10–12 (Altes Wurzelbeet):** Komplexe Wege, Kombination aller Gegnertypen + Bosskampf in Level 12 (Goldener Kern blüht vollständig auf).

## 9. Technische Architektur für Godot 4 (Empfohlene Struktur)

```
res://
├── assets/
│   ├── shaders/          # Aquarell-Post-Processing & Papier-Textur-Shader
│   ├── models/           # Low-Poly 3D-Modelle (Pflanzen, Schädlinge, Beet-Props)
│   └── ui/               # Handgezeichnete Aquarell-Icons & Ring-Menü-Grafiken
├── scenes/
│   ├── main/             # Hauptmenü, Weltkarte (Beet-Auswahl), Gärtner-Buch
│   ├── levels/           # Level-Szenen (Level_01.tscn bis Level_12.tscn)
│   ├── towers/           # Basis-Szene TowerBase.tscn + abgeleitete Pflanzen-Szenen
│   ├── enemies/          # Basis-Szene EnemyBase.tscn + Schnecken, Käfer, Vögel
│   └── ui/               # HUD_Tactical.tscn, HUD_FirstPerson.tscn, RadialMenu.tscn
└── scripts/
    ├── autoload/         # GameManager.gd (Tautropfen, Wellen), SaveManager.gd
    ├── camera/           # CameraRig.gd (Weicher Tween zwischen Vogel- & 1st-Person-Ansicht)
    └── components/       # HealthComponent.gd, HitboxComponent.gd, WeakspotComponent.gd

```

### Erste Aufgaben für Antigravity (Prototyp-Fahrplan)

1. **Umgebungs-Check & Tool-Verbindung:** Godot-4-Pfad, Git und Projektordner prüfen/verknüpfen und dem Nutzer rückmelden, falls noch Pfade, Plugins oder Export-Templates fehlen.

2. **Projekt-Setup:** Godot-4-Projekt im Querformat (`1920x1080`, Stretch-Mode `canvas_items`, Aspect `expand`) mit Mobile-Renderer anlegen.

3. **Kern-Mechanik 1 (Taktik & Pfad):** Ein Test-Beet mit einem `Path3D`, 4 `TowerSpot`-Markierungen, einem `GoldenCore` am Ende und spawnbaren Test-Schnecken bauen.

4. **Kern-Mechanik 2 (Pflanze & Ring-Menü):** Klickbares `RadialMenu` zum Platzieren der *Dornen-Rose*, Gießen (Stufe 2) und Kauf des *Symbiose-Upgrades*.

5. **Kern-Mechanik 3 (Kamera-Wechsel & Touch-Zielen):** `CameraRig.gd` erstellen, das per `Tween` in 0,4 Sek. in den `FirstPersonMount`-Node der Rose fliegt, auf `HUD_FirstPerson` umschaltet und Touch-Drag-Zielen + Auto-Fire aktiviert (inkl. Maus-Simulation für PC-Tests).