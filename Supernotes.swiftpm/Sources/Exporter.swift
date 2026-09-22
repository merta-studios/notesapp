import SwiftUI
import PDFKit
import PencilKit
#if canImport(UIKit)
import UIKit
#endif

/// Renders pages to images / PDF for export and sharing.
@MainActor
enum Exporter {
    /// Compose a full page image: paper background + imported image + drawing.
    static func renderPageImage(item: NoteItem, page: NotePage, scale: CGFloat = 2.0) -> UIImage {
        let size = item.type == .whiteboard ? whiteboardBounds(page: page) : page.template.pageSize
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            // background color
            page.template.background.uiColor.setFill()
            cg.fill(CGRect(origin: .zero, size: size))
            // paper pattern
            drawPattern(page.template, in: CGRect(origin: .zero, size: size), context: cg)
            // imported bg image
            if let bg = NoteStore.shared.loadAssetImage(page.backgroundImageFile) {
                let rect = aspectFit(bg.size, in: CGRect(origin: .zero, size: size))
                bg.draw(in: rect)
            }
            // drawing
            if let data = NoteStore.shared.loadDrawingData(for: page.id),
               let drawing = try? PKDrawing(data: data), !drawing.bounds.isNull {
                let img = drawing.image(from: CGRect(origin: .zero, size: size), scale: scale)
                img.draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }

    private static func whiteboardBounds(page: NotePage) -> CGSize {
        if let data = NoteStore.shared.loadDrawingData(for: page.id),
           let drawing = try? PKDrawing(data: data), !drawing.bounds.isNull {
            let b = drawing.bounds.insetBy(dx: -60, dy: -60)
            return CGSize(width: max(b.width, 400), height: max(b.height, 400))
        }
        return page.template.pageSize
    }

    static func exportImages(item: NoteItem, pageIDs: [UUID]) -> [URL] {
        var urls: [URL] = []
        let live = NoteStore.shared.item(id: item.id) ?? item
        let pages = live.pages.filter { pageIDs.contains($0.id) }
        for (i, page) in pages.enumerated() {
            let img = renderPageImage(item: live, page: page)
            if let data = img.pngData() {
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(live.name)-Seite\(i+1).png")
                try? data.write(to: url)
                urls.append(url)
            }
        }
        return urls
    }

    static func exportPDF(item: NoteItem, pageIDs: [UUID]) -> URL? {
        let live = NoteStore.shared.item(id: item.id) ?? item
        let pages = live.pages.filter { pageIDs.contains($0.id) }
        guard !pages.isEmpty else { return nil }
        let pdf = PDFDocument()
        for (i, page) in pages.enumerated() {
            let img = renderPageImage(item: live, page: page)
            if let pdfPage = PDFPage(image: img) {
                pdf.insert(pdfPage, at: i)
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(live.name).pdf")
        pdf.write(to: url)
        return url
    }

    // helpers
    private static func aspectFit(_ size: CGSize, in rect: CGRect) -> CGRect {
        let scale = min(rect.width / size.width, rect.height / size.height)
        let w = size.width * scale, h = size.height * scale
        return CGRect(x: rect.midX - w/2, y: rect.midY - h/2, width: w, height: h)
    }

    private static func drawPattern(_ template: PaperTemplate, in rect: CGRect, context cg: CGContext) {
        let spacing: CGFloat = 26
        let lum = 0.299*template.background.r + 0.587*template.background.g + 0.114*template.background.b
        let color = (lum < 0.5 ? UIColor.white.withAlphaComponent(0.18) : UIColor(Palette.accent).withAlphaComponent(0.16))
        cg.setStrokeColor(color.cgColor)
        cg.setFillColor(color.cgColor)
        cg.setLineWidth(0.6)
        switch template.style {
        case .blank: break
        case .grid:
            var x = spacing; while x < rect.width { cg.move(to: CGPoint(x: x, y: 0)); cg.addLine(to: CGPoint(x: x, y: rect.height)); x += spacing }
            var y = spacing; while y < rect.height { cg.move(to: CGPoint(x: 0, y: y)); cg.addLine(to: CGPoint(x: rect.width, y: y)); y += spacing }
            cg.strokePath()
        case .lined:
            var y = spacing; while y < rect.height { cg.move(to: CGPoint(x: 0, y: y)); cg.addLine(to: CGPoint(x: rect.width, y: y)); y += spacing }
            cg.strokePath()
        case .dotted:
            var y = spacing
            while y < rect.height {
                var x = spacing
                while x < rect.width { cg.fillEllipse(in: CGRect(x: x-1, y: y-1, width: 2, height: 2)); x += spacing }
                y += spacing
            }
        }
    }
}

/// UIActivityViewController wrapper for sharing exported files.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Small chooser: export as image or PDF, then share.
struct ExportSheet: View {
    let item: NoteItem
    let pageIDs: [UUID]
    @Environment(\.dismiss) private var dismiss
    @State private var shareURLs: [URL] = []
    @State private var showShare = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("\(pageIDs.count) \(pageIDs.count == 1 ? "Seite" : "Seiten") exportieren")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.accentDeep)
                    .padding(.top, 20)

                Button {
                    shareURLs = Exporter.exportImages(item: item, pageIDs: pageIDs)
                    if !shareURLs.isEmpty { showShare = true }
                } label: {
                    exportRow("Als Bild", "photo", "PNG-Dateien")
                }.buttonStyle(.plain)

                Button {
                    if let url = Exporter.exportPDF(item: item, pageIDs: pageIDs) {
                        shareURLs = [url]; showShare = true
                    }
                } label: {
                    exportRow("Als PDF", "doc.richtext", "Ein PDF-Dokument")
                }.buttonStyle(.plain)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Exportieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fertig") { dismiss() } } }
            .sheet(isPresented: $showShare) { ShareSheet(items: shareURLs) }
        }
    }

    private func exportRow(_ title: String, _ icon: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 22, weight: .semibold)).foregroundStyle(Palette.accent).frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(Color.primary)
                Text(subtitle).font(.system(size: 12)).foregroundStyle(Palette.subtitleGray)
            }
            Spacer()
            Image(systemName: "square.and.arrow.up").foregroundStyle(Palette.accent)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.accent.opacity(0.2), lineWidth: 1))
    }
}
