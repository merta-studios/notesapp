import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        HStack(spacing: 0) {
            if app.sidebarOpen {
                Sidebar()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            HomeContent()
                .frame(maxWidth: .infinity)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: app.sidebarOpen)
        .overlay(alignment: .topLeading) {
            if !app.sidebarOpen {
                // Reopen tab handle on the left edge.
                Button {
                    app.sidebarOpen = true
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 18, weight: .semibold))
                }
                .buttonStyle(CircleIconButtonStyle(tint: Palette.accent, size: 44))
                .padding(.top, 24)
                .padding(.leading, 16)
                .transition(.opacity)
            }
        }
    }
}

struct HomeContent: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var store: NoteStore = .shared

    private let columns = [GridItem(.adaptive(minimum: 170, maximum: 210), spacing: 22)]

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            secondaryToolbar
            ScrollView {
                if app.layout == .grid {
                    LazyVGrid(columns: columns, spacing: 24) {
                        newTile
                        ForEach(displayedItems) { item in
                            ItemGridCard(item: item)
                                .environmentObject(app)
                        }
                    }
                    .padding(24)
                } else {
                    LazyVStack(spacing: 12) {
                        newRow
                        ForEach(displayedItems) { item in
                            ItemListRow(item: item)
                                .environmentObject(app)
                        }
                    }
                    .padding(24)
                }
            }
        }
    }

    // MARK: - Data

    private var displayedItems: [NoteItem] {
        let base: [NoteItem]
        switch app.sidebarSection {
        case .documents:
            base = store.children(of: app.currentFolderID)
        case .favorites:
            base = store.favorites()
        }
        return store.sorted(base, by: app.sortOrder)
    }

    // MARK: - Toolbars

    private var topToolbar: some View {
        HStack(spacing: 14) {
            if app.sidebarOpen {
                Button {
                    app.sidebarOpen = false
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 17, weight: .semibold))
                }
                .buttonStyle(CircleIconButtonStyle(size: 42))
            }

            // Breadcrumb / section title
            breadcrumb

            Spacer()

            // Sort selector (segmented pill)
            SortSelector(selection: $app.sortOrder)

            // Settings button top-right
            Button { app.showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
            }
            .buttonStyle(CircleIconButtonStyle(size: 42))
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    private var breadcrumb: some View {
        HStack(spacing: 6) {
            if app.sidebarSection == .favorites {
                Image(systemName: "star.fill").foregroundStyle(Palette.superGradient)
                Text("Favoriten")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.accentDeep)
            } else {
                Button { app.navigateToRoot() } label: {
                    Text("Dokumente")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(app.folderPath.isEmpty ? AnyShapeStyle(Palette.accentDeep) : AnyShapeStyle(Palette.subtitleGray))
                }
                .buttonStyle(.plain)
                ForEach(Array(app.folderPath.enumerated()), id: \.offset) { idx, fid in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.subtitleGray)
                    Button { app.navigateTo(depth: idx) } label: {
                        Text(store.item(id: fid)?.name ?? "Ordner")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(idx == app.folderPath.count - 1 ? AnyShapeStyle(Palette.accentDeep) : AnyShapeStyle(Palette.subtitleGray))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var secondaryToolbar: some View {
        HStack(spacing: 12) {
            Button {
                app.showingNewPicker = true
            } label: {
                HStack(spacing: 8) {
                    PlusGlyph(color: .white, lineWidth: 2.6).frame(width: 16, height: 16)
                    Text("Neu").font(.system(size: 15, weight: .bold, design: .rounded))
                }
            }
            .buttonStyle(GlassButtonStyle(tint: Palette.accent, filled: true))

            // Grid / List toggle
            LayoutToggle(layout: $app.layout)

            Spacer()

            Text("\(displayedItems.count) \(displayedItems.count == 1 ? "Element" : "Elemente")")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.subtitleGray)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    // MARK: - New tiles

    private var newTile: some View {
        Button { app.showingNewPicker = true } label: {
            VStack(alignment: .leading, spacing: 8) {
                DashedNewTile()
                    .aspectRatio(1, contentMode: .fit)
                Color.clear.frame(height: 34)
            }
            .padding(10)
        }
        .buttonStyle(.plain)
        .hoverLift()
    }

    private var newRow: some View {
        Button { app.showingNewPicker = true } label: {
            HStack(spacing: 14) {
                DashedNewTile()
                    .frame(width: 54, height: 54)
                Text("Neu erstellen")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.accent)
                Spacer()
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.45)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sort selector

struct SortSelector: View {
    @Binding var selection: SortOrder
    @State private var expanded = false

    var body: some View {
        Button { expanded = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 13, weight: .semibold))
                Text(selection.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                ChevronDownGlyph(color: Palette.accent, lineWidth: 2).frame(width: 12, height: 12)
            }
        }
        .buttonStyle(GlassButtonStyle(tint: Palette.accent))
        .popover(isPresented: $expanded, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sortieren nach")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.subtitleGray)
                    .padding(.horizontal, 10).padding(.top, 6)
                ForEach(SortOrder.allCases) { order in
                    Button {
                        selection = order; expanded = false
                    } label: {
                        HStack {
                            Text(order.displayName)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if order == selection {
                                Image(systemName: "checkmark").foregroundStyle(Palette.accent)
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .frame(width: 260)
            .presentationCompactAdaptation(.popover)
        }
    }
}

struct LayoutToggle: View {
    @Binding var layout: ContentLayout
    var body: some View {
        HStack(spacing: 2) {
            toggleButton(.grid, icon: "square.grid.2x2.fill")
            toggleButton(.list, icon: "list.bullet")
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 13).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.white.opacity(0.4), lineWidth: 1))
    }

    private func toggleButton(_ value: ContentLayout, icon: String) -> some View {
        Button { layout = value } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 38, height: 32)
                .foregroundStyle(layout == value ? AnyShapeStyle(Color.white) : AnyShapeStyle(Palette.accent))
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(layout == value ? AnyShapeStyle(Palette.accent) : AnyShapeStyle(Color.clear))
                )
        }
        .buttonStyle(.plain)
    }
}
