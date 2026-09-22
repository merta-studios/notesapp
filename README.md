# Supernotes

Eine Notizen-App fürs iPad, gebaut für **Swift Playgrounds** (App-Projekt, `.swiftpm`).

## Öffnen & Starten

1. Dieses Repository auf dein iPad klonen.
2. Den Ordner **`Supernotes.swiftpm`** in **Swift Playgrounds** öffnen.
3. Auf **Ausführen** tippen. iPad-only, Ausrichtung frei.

> Beta-Version. Wird Stück für Stück erweitert.

## Funktionsumfang

**Home**
- Einklappbare Seitenleiste mit einzigartigem **Supernotes**-Titel (das Wort „super" ist besonders hervorgehoben – Farbverlauf, Neigung, Glanz, Sparkle).
- Bereiche: **Dokumente** (Standard), **Favoriten**, **Einstellungen** (großes Overlay über allem, Beta – noch leer).
- Raster/Liste der Notizen. Erstes Element ist immer das gestrichelte **„Neu"**-Kästchen.
- Jede Kachel: quadratisches Icon (aspect ratio 1) = verkleinerte erste Seite, Stern zum Favorisieren, blauer Titel, graues Änderungsdatum, grauer Dropdown-Button (Umbenennen, Öffnen, In neuem Fenster öffnen, Favorit, Papierkorb mit Bestätigung).
- Oben: Einstellungen-Button, Sortierung (Änderungsdatum/Name/Typ/Erstelldatum), Neu-Button, Raster↔Liste-Umschalter.
- **Neu**-Auswahl: Notizbuch, Schnellnotiz, Whiteboard, Ordner (Name+Farbe), Aus Fotos, Aus Dateien (inkl. PDF, mehrere Seiten), Dokument scannen, Foto aufnehmen. Alles endet in einem von drei Typen: **Notizbuch, Whiteboard, Ordner**.

**Geöffnetes Dokument**
- Blaue Tab-Leiste: quadratischer Haus-Button, Tabs (max. halbe Bildschirmbreite, min. Breite, dann scrollbar), jeder Tab mit Name, Schließen-Kreuz (ohne Bestätigung) und Dropdown (Umbenennen, In neuem Fenster öffnen …).
- Zweite Leiste: Seitenliste öffnen (nummeriert, verschieben, mehrfach auswählen, Export/Verschieben/Papierkorb, „+ Seite"), **Nur-lesen-Modus** (Leiste wird grau, Apple Pencil verschiebt das Dokument, Tippen blendet beide Leisten aus/ein). Rechts: Seite hinzufügen (Position, Format, Größe inkl. eigene Pixel, Papier, Farbe, „Vorlage von aktueller Seite") und **…**-Button (Beta-Hinweis).
- **PencilKit** mit Apple-Standard-Toolbar, **Apple Pencil Pro** (Tap/Squeeze), automatisches Speichern und Live-Sync zwischen zwei Fenstern desselben Dokuments.
- Notizbuch: Seiten scrollbar (Lazy-Laden für Performance). Whiteboard: eine unendliche Seite, Titel-Icon zeigt herausgezoomt den gesamten Inhalt.

## Projektstruktur (`Supernotes.swiftpm/Sources`)

- `SupernotesApp.swift` – App-Einstieg, Fenster (Haupt- & Dokumentfenster).
- `Models.swift` / `NoteStore.swift` – Datenmodell & Persistenz (Auto-Save, Multi-Window).
- `Theme.swift` / `CustomIcons.swift` / `SupernotesTitle.swift` – Liquid-Glass-Design, selbst gezeichnete Icons, Wortmarke.
- `HomeView.swift` / `Sidebar.swift` / `ItemCard.swift` / `ItemListRow.swift` – Startseite.
- `NewItemPicker.swift` / `PaperTemplateChooser.swift` / `ImportHelpers.swift` – Erstellen & Importieren.
- `TabBar.swift` / `DocumentContainerView.swift` / `DocumentCanvasArea.swift` / `PencilCanvas.swift` – Editor.
- `PageListPanel.swift` / `AddPageSheet.swift` / `Exporter.swift` / `PageThumbnail.swift` / `PaperBackground.swift` – Seitenverwaltung, Export, Thumbnails.
- `SettingsOverlay.swift` – Einstellungen-Overlay.
