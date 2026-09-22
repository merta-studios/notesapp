import SwiftUI

/// Hosts the currently selected tab's document, plus the two top bars (tabs +
/// tools). Manages read-only mode (which greys the bars, disables editing, and
/// can hide both bars leaving only a small reveal button).
struct DocumentContainerView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var store: NoteStore = .shared

    @State private var readOnly = false
    @State private var barsHidden = false
    @State private var showPageList = false
    @State private var currentPageIndex = 0
    @State private var selectedPageIDs: Set<UUID> = []

    @State private var showAddPage = false
    @State private var showMoreMenu = false
    @State private var exportPageIDs: [UUID]? = nil
    @State private var scrollTargetIndex: Int? = nil

    private var currentItem: NoteItem? {
        store.item(id: app.selectedTabID)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main content region
            VStack(spacing: 0) {
                if !barsHidden {
                    DocumentTabBar(readOnly: readOnly)
                        .environmentObject(app)
                    toolBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                HStack(spacing: 0) {
                    if showPageList, let item = currentItem, item.type == .notebook {
                        PageListPanel(item: item,
                                      currentPageIndex: $currentPageIndex,
                                      selectedPageIDs: $selectedPageIDs,
                                      onAddPage: { showAddPage = true },
                                      onExport: { exportPageIDs = $0 },
                                      onScrollToPage: { scrollTargetIndex = $0 })
                            .environmentObject(app)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    if let item = currentItem {
                        DocumentCanvasArea(item: item,
                                           readOnly: $readOnly,
                                           barsHidden: $barsHidden,
                                           currentPageIndex: $currentPageIndex,
                                           scrollTargetIndex: $scrollTargetIndex,
                                           showsToolPicker: !readOnly)
                            .id(item.id)
                    } else {
                        emptyState
                    }
                }
            }

            // Reveal button when bars hidden
            if barsHidden {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { barsHidden = false }
                } label: {
                    ChevronDownGlyph(color: .white, lineWidth: 2.4)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(CircleIconButtonStyle(tint: Palette.accent, size: 42, filled: true))
                .padding(.top, 12)
                .padding(.leading, 12)
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsHidden)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showPageList)
        .onChange(of: app.selectedTabID) { _, _ in
            selectedPageIDs = []
            restoreLastPage()
        }
        .onAppear { restoreLastPage() }
        .sheet(isPresented: $showAddPage) {
            if let item = currentItem {
                AddPageSheet(item: item, currentPageIndex: currentPageIndex) { insertedIndex in
                    currentPageIndex = insertedIndex
                    scrollTargetIndex = insertedIndex
                }
            }
        }
        .sheet(isPresented: Binding(get: { exportPageIDs != nil }, set: { if !$0 { exportPageIDs = nil } })) {
            if let item = currentItem, let ids = exportPageIDs {
                ExportSheet(item: item, pageIDs: ids)
            }
        }
    }

    private func restoreLastPage() {
        if let item = currentItem {
            currentPageIndex = min(max(0, item.lastOpenedPageIndex), max(0, item.pages.count - 1))
            scrollTargetIndex = currentPageIndex
        }
    }

    // MARK: - Tool bar (second bar)

    private var toolBar: some View {
        HStack(spacing: 10) {
            // LEFT group
            // page list toggle (only notebooks)
            if currentItem?.type == .notebook {
                toolButton(systemImage: "sidebar.squares.left", active: showPageList) {
                    withAnimation { showPageList.toggle() }
                }
            }
            // read-only toggle
            toolButton(systemImage: readOnly ? "lock.fill" : "lock.open", active: readOnly) {
                withAnimation { readOnly.toggle() }
                if !readOnly { barsHidden = false }
            }

            Spacer()

            // (middle intentionally empty for now)

            Spacer()

            // RIGHT group
            // add page (not for whiteboard)
            if currentItem?.type == .notebook {
                Button { showAddPage = true } label: {
                    PlusGlyph(color: .white, lineWidth: 2.6).frame(width: 16, height: 16)
                }
                .buttonStyle(CircleIconButtonStyle(tint: readOnly ? Palette.readOnlyBar : Palette.accent, size: 40, filled: true))
                .disabled(readOnly)
            }

            // more (…)
            Button { showMoreMenu = true } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
            }
            .buttonStyle(CircleIconButtonStyle(tint: readOnly ? Palette.readOnlyBar : Palette.accent, size: 40))
            .popover(isPresented: $showMoreMenu, arrowEdge: .top) {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles").font(.system(size: 26)).foregroundStyle(Palette.superGradient)
                    Text("Beta Version")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.accentDeep)
                    Text("Dies ist eine Beta Version, deshalb gibt es hier noch nichts.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.subtitleGray)
                }
                .padding(20)
                .frame(width: 260)
                .presentationCompactAdaptation(.popover)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            (readOnly ? AnyShapeStyle(Palette.readOnlyBar.opacity(0.92)) : AnyShapeStyle(.ultraThinMaterial))
        )
        .overlay(Divider().opacity(0.3), alignment: .bottom)
    }

    private func toolButton(systemImage: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
        }
        .buttonStyle(CircleIconButtonStyle(tint: readOnly ? Palette.readOnlyBar : Palette.accent, size: 40, filled: active))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Sparkle().frame(width: 50, height: 50)
            Text("Kein Dokument geöffnet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.subtitleGray)
            Button("Zur Startseite") { app.goHome() }
                .buttonStyle(GlassButtonStyle(tint: Palette.accent, filled: true))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
