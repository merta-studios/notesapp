import SwiftUI

/// Draws the paper template look (grid / lines / dots / blank) plus the paper
/// background color. Rendered behind the PencilKit canvas.
struct PaperBackgroundView: View {
    let template: PaperTemplate

    var body: some View {
        Canvas { context, size in
            // Fill background color
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(template.background.color))

            let spacing: CGFloat = 26
            let lineColor = strokeColor
            switch template.style {
            case .blank:
                break
            case .grid:
                var x: CGFloat = spacing
                while x < size.width {
                    context.stroke(linePath(from: CGPoint(x: x, y: 0), to: CGPoint(x: x, y: size.height)),
                                   with: .color(lineColor), lineWidth: 0.6)
                    x += spacing
                }
                var y: CGFloat = spacing
                while y < size.height {
                    context.stroke(linePath(from: CGPoint(x: 0, y: y), to: CGPoint(x: size.width, y: y)),
                                   with: .color(lineColor), lineWidth: 0.6)
                    y += spacing
                }
            case .lined:
                var y: CGFloat = spacing
                while y < size.height {
                    context.stroke(linePath(from: CGPoint(x: 0, y: y), to: CGPoint(x: size.width, y: y)),
                                   with: .color(lineColor), lineWidth: 0.6)
                    y += spacing
                }
            case .dotted:
                var y: CGFloat = spacing
                while y < size.height {
                    var x: CGFloat = spacing
                    while x < size.width {
                        let dot = Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                        context.fill(dot, with: .color(lineColor))
                        x += spacing
                    }
                    y += spacing
                }
            }
        }
    }

    private var strokeColor: Color {
        // choose contrast based on background luminance
        let lum = 0.299 * template.background.r + 0.587 * template.background.g + 0.114 * template.background.b
        return lum < 0.5 ? Color.white.opacity(0.18) : Palette.accent.opacity(0.16)
    }

    private func linePath(from: CGPoint, to: CGPoint) -> Path {
        var p = Path(); p.move(to: from); p.addLine(to: to); return p
    }
}
