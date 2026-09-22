import SwiftUI

/// The "Neu" picker: a grid of all creation options. Selecting one either opens
/// a follow-up sheet (folder / notebook template / whiteboard template) or an
/// import flow (photos / files / scan / camera), all of which end up creating
/// one of the three real item types.
struct NewItemPickerOverlay: View {
    @Binding var isPresented: Bool
    var targetFolderID: UUID?
    @EnvironmentObject var app: AppState
    @ObservedObject var store: NoteStore = .shared

    enum Route: Identifiable {
        case folder, notebook, whiteboard
        case photos, files, scan, camera
        var id: Int { switch self { case .folder: 0; case .notebook: 1; case .whiteboard: 2; case .photos: 3; case .files: 4; case .scan: 5; case .camera: 6 } }
    }
    @State private var route: Route?

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 190), spacing: 18)]

    private struct Option: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let tint: Color
        let route: Route
    }

    private var options: [Option] {
        [
            Option(title: "Notizbuch", systemImage: "book.closed.fill", tint: Palette.accent, route: .notebook),
            Option(title: "Schnellnotiz", systemImage: "bolt.fill", tint: Palette.superOrange, route: .notebook),
            Option(title: "Whiteboard", systemImage: "rectangle.dashed", tint: Palette.superPink, route: .whiteboard),
            Option(title: "Ordner", systemImage: "folder.fill", tint: RGBAColor.folderPalette[2].color, route: .folder),
            Option(title: "Aus Fotos wählen", systemImage: "photo.on.rectangle", tint: RGBAColor.folderPalette[1].color, route: .photos),
            Option(title: "Aus Dateien wählen", systemImage: "doc.fill", tint: RGBAColor.folderPalette[4].color, route: .files),
            Option(title: "Dokument scannen", systemImage: "doc.viewfinder", tint: RGBAColor.folderPalette[5].color, route: .scan),
            Option(title: "Foto aufnehmen", systemImage: "camera.fill", tint: RGBAColor.folderPalette[3].color, route: .camera)
        ]
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea().onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 10) {
                        PlusGlyph(color: Palette.accent, lineWidth: 3).frame(width: 22, height: 22)
                        Text("Neu erstellen")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.accentDeep)
                    }
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .bold))
                    }.buttonStyle(CircleIconButtonStyle(size: 40))
                }
                .padding(24)
                Divider().opacity(0.4)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(options) { opt in
                            NewOptionTile(title: opt.title, systemImage: opt.systemImage, tint: opt.tint) {
                                route = opt.route
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .frame(maxWidth: 720, maxHeight: 620)
            .liquidGlass(cornerRadius: 34)
            .padding(40)
        }
        .sheet(item: $route) { r in
            routeSheet(r)
        }
    }

    @ViewBuilder
    private func routeSheet(_ r: Route) -> some View {
        switch r {
        case .folder:
            NewFolderSheet(targetFolderID: targetFolderID) { created in
                finish(created)
            }
        case .notebook:
            NewCanvasSheet(kind: .notebook, targetFolderID: targetFolderID) { created in
                finish(created)
            }
        case .whiteboard:
            NewCanvasSheet(kind: .whiteboard, targetFolderID: targetFolderID) { created in
                finish(created)
            }
        case .photos:
            PhotoImportPicker { images in
                route = nil
                let pages = PageImporter.pages(fromImages: images)
                if !pages.isEmpty {
                    let item = store.createNotebook(name: "Fotos", parentID: targetFolderID, template: .defaultNotebook, pages: pages)
                    finish(item)
                }
            }
        case .files:
            FileImportPicker { pages in
                route = nil
                if !pages.isEmpty {
                    let item = store.createNotebook(name: "Import", parentID: targetFolderID, template: .defaultNotebook, pages: pages)
                    finish(item)
                }
            }
        case .scan:
            DocumentScanner { images in
                route = nil
                let pages = PageImporter.pages(fromImages: images)
                if !pages.isEmpty {
                    let item = store.createNotebook(name: "Scan", parentID: targetFolderID, template: .defaultNotebook, pages: pages)
                    finish(item)
                }
            }
        case .camera:
            CameraPicker { images in
                route = nil
                let pages = PageImporter.pages(fromImages: images)
                if !pages.isEmpty {
                    let item = store.createNotebook(name: "Foto", parentID: targetFolderID, template: .defaultNotebook, pages: pages)
                    finish(item)
                }
            }
        }
    }

    private func finish(_ item: NoteItem?) {
        route = nil
        isPresented = false
        if let item, item.type != .folder {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                app.open(item.id)
            }
        }
    }
}

struct NewOptionTile: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(tint.opacity(0.16))
                        .frame(width: 74, height: 74)
                    Image(systemName: systemImage)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(hovering ? 0.8 : 0.5))
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(tint.opacity(hovering ? 0.5 : 0.15), lineWidth: 1.5))
            )
            .scaleEffect(hovering ? 1.04 : 1)
            .shadow(color: tint.opacity(hovering ? 0.25 : 0), radius: 14, y: 6)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

// MARK: - New folder sheet

struct NewFolderSheet: View {
    var targetFolderID: UUID?
    var onCreate: (NoteItem?) -> Void
    @ObservedObject var store: NoteStore = .shared
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = "Neuer Ordner"
    @State private var colorIndex: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        FolderIcon(color: RGBAColor.folderPalette[colorIndex].color)
                            .frame(width: 90, height: 90)
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Palette.subtitleGray)
                        TextField("Ordnername", text: $name)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Farbe").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Palette.subtitleGray)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 46))], spacing: 12) {
                            ForEach(Array(RGBAColor.folderPalette.enumerated()), id: \.offset) { idx, c in
                                Button { colorIndex = idx } label: {
                                    Circle().fill(c.color).frame(width: 40, height: 40)
                                        .overlay(Circle().strokeBorder(colorIndex == idx ? Palette.accentDeep : Color.clear, lineWidth: 3))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Neuer Ordner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCreate(nil); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        let item = store.createFolder(name: n.isEmpty ? "Neuer Ordner" : n,
                                                      color: RGBAColor.folderPalette[colorIndex],
                                                      parentID: targetFolderID)
                        onCreate(item); dismiss()
                    }.fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - New notebook / whiteboard sheet (choose starting paper template)

struct NewCanvasSheet: View {
    enum Kind { case notebook, whiteboard }
    let kind: Kind
    var targetFolderID: UUID?
    var onCreate: (NoteItem?) -> Void
    @ObservedObject var store: NoteStore = .shared
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var template: PaperTemplate

    init(kind: Kind, targetFolderID: UUID?, onCreate: @escaping (NoteItem?) -> Void) {
        self.kind = kind
        self.targetFolderID = targetFolderID
        self.onCreate = onCreate
        _name = State(initialValue: kind == .notebook ? "Neues Notizbuch" : "Neues Whiteboard")
        _template = State(initialValue: kind == .notebook ? .defaultNotebook : .defaultWhiteboard)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Palette.subtitleGray)
                        TextField("Name", text: $name)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    }
                    PaperTemplateChooser(template: $template, allowLined: kind == .notebook)
                }
                .padding(24)
            }
            .navigationTitle(kind == .notebook ? "Neues Notizbuch" : "Neues Whiteboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCreate(nil); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        let finalName = n.isEmpty ? (kind == .notebook ? "Notizbuch" : "Whiteboard") : n
                        let item: NoteItem
                        if kind == .notebook {
                            item = store.createNotebook(name: finalName, parentID: targetFolderID, template: template)
                        } else {
                            item = store.createWhiteboard(name: finalName, parentID: targetFolderID, template: template)
                        }
                        onCreate(item); dismiss()
                    }.fontWeight(.bold)
                }
            }
        }
    }
}
