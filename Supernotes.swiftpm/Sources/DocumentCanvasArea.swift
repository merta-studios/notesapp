import SwiftUI

/// The scrollable drawing area for a notebook (pages stacked vertically) or a
/// whiteboard (a single, effectively-infinite page).
///
/// Performance: notebook pages are hosted in a LazyVStack so PencilKit canvases
/// are only instantiated when scrolled near, keeping memory flat as page count
/// grows. Each page reports its position so we can track "current page" and
/// remember it for next open.
struct DocumentCanvasArea: View {
    let item: NoteItem
    @Binding var readOnly: Bool
    @Binding var barsHidden: Bool
    @Binding var currentPageIndex: Int
    @Binding var scrollTargetIndex: Int?
    var showsToolPicker: Bool

    @ObservedObject var store: NoteStore = .shared

    private var liveItem: NoteItem { store.item(id: item.id) ?? item }

    var body: some View {
        Group {
            if liveItem.type == .whiteboard {
                whiteboardView
            } else {
                notebookView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Tap while read-only toggles the chrome (both bars).
        .overlay {
            if readOnly {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            barsHidden.toggle()
                        }
                    }
                    .allowsHitTesting(true)
            }
        }
    }

    // MARK: - Notebook (vertical scrolling pages)

    private var notebookView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 28) {
                    ForEach(Array(liveItem.pages.enumerated()), id: \.element.id) { index, page in
                        PageCanvasCell(item: liveItem, page: page, index: index,
                                       readOnly: $readOnly,
                                       showsToolPicker: showsToolPicker && index == currentPageIndex)
                            .id(index)
                            .background(
                                GeometryReader { geo -> Color in
                                    let midY = geo.frame(in: .named("scroll")).midY
                                    DispatchQueue.main.async {
                                        // If this page's middle is near the viewport center, mark it current.
                                        if abs(midY - UIScreen.main.bounds.height/2) < 260 {
                                            if currentPageIndex != index {
                                                currentPageIndex = index
                                                store.setLastOpenedPage(item.id, index: index)
                                            }
                                        }
                                    }
                                    return Color.clear
                                }
                            )
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
            .coordinateSpace(name: "scroll")
            .onChange(of: scrollTargetIndex) { _, target in
                if let t = target {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(t, anchor: .top)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { scrollTargetIndex = nil }
                }
            }
            .onAppear {
                if let idx = scrollTargetIndex ?? Optional(currentPageIndex) {
                    proxy.scrollTo(idx, anchor: .top)
                }
            }
        }
    }

    // MARK: - Whiteboard (infinite canvas)

    private var whiteboardView: some View {
        // A large scrollable canvas that pans in all directions.
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            if let page = liveItem.pages.first {
                let big = CGSize(width: 4000, height: 4000)
                ZStack {
                    PaperBackgroundView(template: page.template)
                    PencilCanvas(pageID: page.id, itemID: liveItem.id,
                                 template: page.template,
                                 isReadOnly: $readOnly,
                                 showsToolPicker: showsToolPicker)
                }
                .frame(width: big.width, height: big.height)
                .background(page.template.background.color)
            }
        }
    }
}

/// A single notebook page: paper + optional imported image + PencilKit canvas,
/// laid out at the page's real aspect ratio and scaled to fit the width.
struct PageCanvasCell: View {
    let item: NoteItem
    let page: NotePage
    let index: Int
    @Binding var readOnly: Bool
    var showsToolPicker: Bool
    @ObservedObject var store: NoteStore = .shared

    var body: some View {
        GeometryReader { geo in
            let pageSize = page.template.pageSize
            let maxWidth = min(geo.size.width, 900)
            let scale = maxWidth / pageSize.width
            let displaySize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)

            ZStack {
                PaperBackgroundView(template: page.template)
                if let bg = store.loadAssetImage(page.backgroundImageFile) {
                    Image(uiImage: bg).resizable().aspectRatio(contentMode: .fit)
                }
                PencilCanvas(pageID: page.id, itemID: item.id,
                             template: page.template,
                             isReadOnly: $readOnly,
                             showsToolPicker: showsToolPicker)
            }
            .frame(width: displaySize.width, height: displaySize.height)
            .background(page.template.background.color)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
            .overlay(alignment: .topTrailing) {
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.subtitleGray)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .offset(x: -8, y: 8)
            }
            .frame(width: geo.size.width, alignment: .center)
        }
        .frame(height: pageDisplayHeight)
    }

    /// Approximate display height so LazyVStack can size the row before layout.
    private var pageDisplayHeight: CGFloat {
        let pageSize = page.template.pageSize
        let assumedWidth: CGFloat = min(UIScreen.main.bounds.width * 0.75, 900)
        let scale = assumedWidth / pageSize.width
        return pageSize.height * scale
    }
}
