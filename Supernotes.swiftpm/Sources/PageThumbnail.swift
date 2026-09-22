import SwiftUI
import PencilKit

/// Renders a static thumbnail of a page: paper background + optional imported
/// image + the PencilKit drawing rendered to an image. For whiteboards it zooms
/// out so the entire drawn content is visible.
struct PageThumbnail: View {
    let page: NotePage
    let isWhiteboard: Bool
    @ObservedObject var store: NoteStore = .shared

    @State private var drawingImage: UIImage?
    @State private var renderedRevision: Int = -1

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PaperBackgroundView(template: page.template)
                if let bg = store.loadAssetImage(page.backgroundImageFile) {
                    Image(uiImage: bg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                if let img = drawingImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .onAppear { renderIfNeeded() }
        .onChange(of: store.drawingRevisions[page.id] ?? 0) { _, _ in renderIfNeeded(force: true) }
    }

    private func renderIfNeeded(force: Bool = false) {
        let rev = store.drawingRevisions[page.id] ?? 0
        if !force && rev == renderedRevision && drawingImage != nil { return }
        renderedRevision = rev
        guard let data = store.loadDrawingData(for: page.id),
              let drawing = try? PKDrawing(data: data), !drawing.bounds.isNull else {
            drawingImage = nil
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let bounds: CGRect
            if isWhiteboard {
                // zoom out to fit everything drawn
                bounds = drawing.bounds.insetBy(dx: -40, dy: -40)
            } else {
                bounds = CGRect(origin: .zero, size: page.template.pageSize)
            }
            let targetWidth: CGFloat = 300
            let scale = targetWidth / max(bounds.width, 1)
            let img = drawing.image(from: bounds, scale: scale)
            DispatchQueue.main.async {
                self.drawingImage = img
            }
        }
    }
}

/// The square (aspect ratio 1) icon for an item shown on the home grid: the
/// first page rendered smaller so it fits inside the square with padding.
struct ItemSquareIcon: View {
    let item: NoteItem

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.sRGB, red: 0.93, green: 0.94, blue: 0.97))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.7), lineWidth: 1))

            switch item.type {
            case .folder:
                FolderIcon(color: (item.folderColor ?? RGBAColor.folderPalette[0]).color)
                    .padding(20)
            case .notebook, .whiteboard:
                if let first = item.pages.first {
                    // The real "icon" is the first page, scaled down to fit the
                    // square with a margin, keeping the page's own aspect ratio.
                    GeometryReader { geo in
                        let side = min(geo.size.width, geo.size.height)
                        let pageSize = item.type == .whiteboard
                            ? CGSize(width: 1, height: 0.72) // wide-ish preview
                            : first.template.pageSize
                        let ar = pageSize.width / max(pageSize.height, 1)
                        let maxContent = side * 0.78
                        let w = ar >= 1 ? maxContent : maxContent * ar
                        let h = ar >= 1 ? maxContent / ar : maxContent
                        PageThumbnail(page: first, isWhiteboard: item.type == .whiteboard)
                            .frame(width: w, height: h)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
                // small type badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        typeBadge
                            .padding(10)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var typeBadge: some View {
        Group {
            switch item.type {
            case .whiteboard:
                Image(systemName: "rectangle.dashed")
                    .font(.system(size: 12, weight: .bold))
            case .notebook:
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 12, weight: .bold))
            case .folder:
                EmptyView()
            }
        }
        .foregroundStyle(.white)
        .padding(6)
        .background(Circle().fill(Palette.accent.opacity(0.85)))
        .shadow(radius: 2)
    }
}
