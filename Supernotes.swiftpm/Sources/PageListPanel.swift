import SwiftUI

/// Left panel listing all pages of a notebook: numbered, 2-column grid, drag to
/// reorder, multi-select, per-page dropdown (trash / new window / export / move),
/// and a dashed "add page" tile at the bottom.
struct PageListPanel: View {
    let item: NoteItem
    @Binding var currentPageIndex: Int
    @Binding var selectedPageIDs: Set<UUID>
    var onAddPage: () -> Void
    var onExport: ([UUID]) -> Void
    var onScrollToPage: (Int) -> Void

    @ObservedObject var store: NoteStore = .shared
    @EnvironmentObject var app: AppState
    @Environment(\.openWindow) private var openWindow

    @State private var moveTargetPickerFor: [UUID]? = nil
    @State private var confirmTrash: [UUID]? = nil

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var liveItem: NoteItem { store.item(id: item.id) ?? item }

    var body: some View {
        VStack(spacing: 0) {
            // Header with multi-select actions
            HStack {
                Text("Seiten")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.accentDeep)
                Spacer()
                if !selectedPageIDs.isEmpty {
                    Text("\(selectedPageIDs.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Palette.accent))
                }
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            if !selectedPageIDs.isEmpty {
                multiSelectToolbar
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(liveItem.pages.enumerated()), id: \.element.id) { index, page in
                        pageCell(page: page, index: index)
                    }
                    // dashed add page tile
                    Button(action: onAddPage) {
                        DashedNewTile(title: "Seite")
                            .frame(height: 150)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
            }
        }
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.5), lineWidth: 1))
        )
        .padding(.vertical, 10)
        .padding(.leading, 10)
        .sheet(isPresented: Binding(get: { moveTargetPickerFor != nil }, set: { if !$0 { moveTargetPickerFor = nil } })) {
            MovePagesSheet(sourceItem: liveItem, pageIDs: moveTargetPickerFor ?? []) {
                moveTargetPickerFor = nil
                selectedPageIDs = []
            }
        }
        .alert("Seite(n) in den Papierkorb?", isPresented: Binding(get: { confirmTrash != nil }, set: { if !$0 { confirmTrash = nil } })) {
            Button("Abbrechen", role: .cancel) { confirmTrash = nil }
            Button("In den Papierkorb", role: .destructive) {
                if let ids = confirmTrash {
                    store.deletePages(Set(ids), from: item.id)
                    selectedPageIDs = []
                    currentPageIndex = max(0, min(currentPageIndex, (store.item(id: item.id)?.pages.count ?? 1) - 1))
                }
                confirmTrash = nil
            }
        } message: { Text("Die ausgewählten Seiten werden entfernt.") }
    }

    private var multiSelectToolbar: some View {
        HStack(spacing: 8) {
            smallAction("Export", "square.and.arrow.up") { onExport(Array(selectedPageIDs)) }
            smallAction("Verschieben", "folder") { moveTargetPickerFor = Array(selectedPageIDs) }
            smallAction("Papierkorb", "trash", destructive: true) { confirmTrash = Array(selectedPageIDs) }
            Button { selectedPageIDs = [] } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.subtitleGray)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    private func smallAction(_ title: String, _ icon: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                Text(title).font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(destructive ? Color.red : Palette.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.5)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func pageCell(page: NotePage, index: Int) -> some View {
        let isSelected = selectedPageIDs.contains(page.id)
        let isCurrent = index == currentPageIndex
        VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                PageThumbnail(page: page, isWhiteboard: liveItem.type == .whiteboard)
                    .frame(height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isCurrent ? Palette.accent : (isSelected ? Palette.superPink : Color.black.opacity(0.1)),
                                          lineWidth: isCurrent || isSelected ? 3 : 1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !selectedPageIDs.isEmpty {
                            toggleSelect(page.id)
                        } else {
                            currentPageIndex = index
                            onScrollToPage(index)
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.35) {
                        toggleSelect(page.id)
                    }

                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(Palette.accent.opacity(0.9)))
                    .padding(6)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Palette.superPink)
                        .background(Circle().fill(.white))
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                }
            }
            HStack {
                Text("Seite \(index + 1)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.subtitleGray)
                Spacer()
                PageCellMenu(item: liveItem, page: page, index: index,
                             onExport: { onExport([page.id]) },
                             onMove: { moveTargetPickerFor = [page.id] },
                             onTrash: { confirmTrash = [page.id] })
                    .environmentObject(app)
            }
        }
        .draggable("\(index)") {
            PageThumbnail(page: page, isWhiteboard: liveItem.type == .whiteboard)
                .frame(width: 80, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .dropDestination(for: String.self) { droppedItems, _ in
            guard let first = droppedItems.first, let from = Int(first) else { return false }
            store.movePage(in: item.id, from: IndexSet(integer: from), to: index > from ? index + 1 : index)
            return true
        }
    }

    private func toggleSelect(_ id: UUID) {
        if selectedPageIDs.contains(id) { selectedPageIDs.remove(id) } else { selectedPageIDs.insert(id) }
    }
}

/// Per-page dropdown menu (chevron under each page).
struct PageCellMenu: View {
    let item: NoteItem
    let page: NotePage
    let index: Int
    var onExport: () -> Void
    var onMove: () -> Void
    var onTrash: () -> Void
    @EnvironmentObject var app: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var show = false

    var body: some View {
        Button { show = true } label: {
            ChevronDownGlyph(color: Palette.subtitleGray, lineWidth: 2)
                .frame(width: 12, height: 12)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $show, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 4) {
                MenuButton(icon: "trash", title: "In den Papierkorb", role: .destructive) { show = false; onTrash() }
                MenuButton(icon: "plus.rectangle.on.rectangle", title: "In neuem Fenster öffnen") {
                    show = false
                    openWindow(id: "document", value: DocumentWindowValue(itemID: item.id, pageID: page.id))
                }
                MenuButton(icon: "square.and.arrow.up", title: "Exportieren") { show = false; onExport() }
                MenuButton(icon: "folder", title: "Zu Notizbuch verschieben") { show = false; onMove() }
            }
            .padding(10)
            .frame(width: 260)
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Move pages sheet

struct MovePagesSheet: View {
    let sourceItem: NoteItem
    let pageIDs: [UUID]
    var onDone: () -> Void
    @ObservedObject var store: NoteStore = .shared
    @Environment(\.dismiss) private var dismiss

    private var targets: [NoteItem] {
        store.items.filter { $0.type == .notebook && !$0.isTrashed && $0.id != sourceItem.id }
    }

    var body: some View {
        NavigationStack {
            List {
                if targets.isEmpty {
                    Text("Keine anderen Notizbücher vorhanden.")
                        .foregroundStyle(Palette.subtitleGray)
                }
                ForEach(targets) { target in
                    Button {
                        store.movePages(pageIDs, from: sourceItem.id, to: target.id)
                        onDone(); dismiss()
                    } label: {
                        HStack {
                            ItemSquareIcon(item: target).frame(width: 40, height: 40)
                            Text(target.name)
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                }
            }
            .navigationTitle("Verschieben nach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { onDone(); dismiss() } }
            }
        }
    }
}
