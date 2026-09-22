import SwiftUI

@main
struct SupernotesApp: App {
    @StateObject private var store = NoteStore.shared

    var body: some Scene {
        // Main window
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Palette.accent)
        }

        // Dedicated document windows ("In neuem Fenster öffnen").
        // Opening this scene with a DocumentWindowValue spawns a second iPad
        // window showing exactly that document.
        WindowGroup(id: "document", for: DocumentWindowValue.self) { $value in
            DedicatedDocumentWindow(value: value)
                .environmentObject(store)
                .tint(Palette.accent)
        }
    }
}

/// The root view of a normal window: either the home screen or an open document,
/// with the tab / toolbar chrome. Global overlays (settings, new picker) sit on
/// top of everything.
struct RootView: View {
    @StateObject private var app = AppState()

    var body: some View {
        ZStack {
            AppBackground()

            Group {
                switch app.mode {
                case .home:
                    HomeView()
                case .document:
                    DocumentContainerView()
                }
            }
            .environmentObject(app)

            // Settings overlay — appears over everything.
            if app.showingSettings {
                SettingsOverlay(isPresented: $app.showingSettings)
                    .environmentObject(app)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(10)
            }

            // New item picker overlay.
            if app.showingNewPicker {
                NewItemPickerOverlay(isPresented: $app.showingNewPicker,
                                     targetFolderID: app.currentFolderID)
                    .environmentObject(app)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(11)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: app.showingSettings)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: app.showingNewPicker)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: app.mode)
    }
}

/// A window opened via "In neuem Fenster öffnen" — shows just one document with
/// its own toolbar, sharing the same NoteStore so edits sync live.
struct DedicatedDocumentWindow: View {
    let value: DocumentWindowValue?
    @StateObject private var app = AppState()

    var body: some View {
        ZStack {
            AppBackground()
            if let value, NoteStore.shared.item(id: value.itemID) != nil {
                DocumentContainerView()
                    .environmentObject(app)
                    .onAppear {
                        app.isDedicatedWindow = true
                        app.openTabs = [value.itemID]
                        app.selectedTabID = value.itemID
                        app.mode = .document
                    }
            } else {
                VStack(spacing: 12) {
                    Text("Dokument nicht gefunden")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Palette.subtitleGray)
                }
            }

            if app.showingSettings {
                SettingsOverlay(isPresented: $app.showingSettings)
                    .environmentObject(app)
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: app.showingSettings)
    }
}
