import SwiftUI

// Custom hand-built icons drawn with SwiftUI Shapes / Canvas so the app has its
// own visual identity rather than relying only on SF Symbols.

// MARK: - House icon (home button in tab bar)

struct HouseIcon: View {
    var color: Color = .white
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // Roof + body drawn as one filled shape.
                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.12))
                    p.addLine(to: CGPoint(x: w * 0.92, y: h * 0.48))
                    p.addLine(to: CGPoint(x: w * 0.08, y: h * 0.48))
                    p.closeSubpath()
                }
                .fill(color)
                RoundedRectangle(cornerRadius: w * 0.06)
                    .fill(color)
                    .frame(width: w * 0.62, height: h * 0.40)
                    .position(x: w * 0.5, y: h * 0.66)
                // Door punched out via a darker overlay tint.
                RoundedRectangle(cornerRadius: w * 0.03)
                    .fill(color.opacity(0.0))
                    .frame(width: w * 0.16, height: h * 0.24)
                    .overlay(
                        RoundedRectangle(cornerRadius: w * 0.03)
                            .strokeBorder(Palette.accentDeep.opacity(0.35), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: w * 0.03).fill(Palette.accentDeep.opacity(0.28)))
                    )
                    .frame(width: w * 0.16, height: h * 0.24)
                    .position(x: w * 0.5, y: h * 0.74)
            }
        }
    }
}

// MARK: - Notebook icon

struct NotebookIcon: View {
    var accent: Color = Palette.accent
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.12, style: .continuous)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: w * 0.12).strokeBorder(accent.opacity(0.25), lineWidth: 1))
                // spiral binding
                RoundedRectangle(cornerRadius: w * 0.12, style: .continuous)
                    .fill(accent)
                    .frame(width: w * 0.16)
                    .position(x: w * 0.10, y: h * 0.5)
                ForEach(0..<5) { i in
                    Circle().fill(Color.white)
                        .frame(width: w * 0.05, height: w * 0.05)
                        .position(x: w * 0.10, y: h * (0.2 + Double(i) * 0.15))
                }
                // lines
                VStack(alignment: .leading, spacing: h * 0.11) {
                    ForEach(0..<4) { _ in
                        Capsule().fill(accent.opacity(0.3)).frame(height: h * 0.035)
                    }
                }
                .frame(width: w * 0.55)
                .position(x: w * 0.56, y: h * 0.5)
            }
        }
    }
}

// MARK: - Whiteboard icon

struct WhiteboardIcon: View {
    var accent: Color = Palette.accent
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.10, style: .continuous)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: w * 0.10).strokeBorder(accent.opacity(0.3), lineWidth: 1.5))
                    .frame(height: h * 0.7)
                    .position(x: w * 0.5, y: h * 0.42)
                // squiggle
                Path { p in
                    p.move(to: CGPoint(x: w * 0.22, y: h * 0.45))
                    p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.3),
                               control1: CGPoint(x: w * 0.32, y: h * 0.2),
                               control2: CGPoint(x: w * 0.42, y: h * 0.55))
                    p.addCurve(to: CGPoint(x: w * 0.78, y: h * 0.42),
                               control1: CGPoint(x: w * 0.6, y: h * 0.1),
                               control2: CGPoint(x: w * 0.72, y: h * 0.5))
                }
                .stroke(Palette.superPink, style: StrokeStyle(lineWidth: w * 0.05, lineCap: .round))
                // stand
                Rectangle().fill(accent).frame(width: w * 0.05, height: h * 0.2)
                    .position(x: w * 0.5, y: h * 0.82)
                Path { p in
                    p.move(to: CGPoint(x: w * 0.3, y: h * 0.95))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.8))
                    p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.95))
                }
                .stroke(accent, style: StrokeStyle(lineWidth: w * 0.045, lineCap: .round))
            }
        }
    }
}

// MARK: - Folder icon

struct FolderIcon: View {
    var color: Color = Color.folderPalette0
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // back tab
                RoundedRectangle(cornerRadius: w * 0.08, style: .continuous)
                    .fill(color.opacity(0.85))
                    .frame(width: w * 0.5, height: h * 0.3)
                    .position(x: w * 0.34, y: h * 0.3)
                // body
                RoundedRectangle(cornerRadius: w * 0.10, style: .continuous)
                    .fill(
                        LinearGradient(colors: [color, color.opacity(0.78)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: w * 0.86, height: h * 0.52)
                    .position(x: w * 0.5, y: h * 0.6)
                    .overlay(
                        RoundedRectangle(cornerRadius: w * 0.10)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: w * 0.86, height: h * 0.12)
                            .position(x: w * 0.5, y: h * 0.4)
                    )
            }
        }
    }
}

extension Color {
    static let folderPalette0 = RGBAColor.folderPalette[0].color
}

// MARK: - Small custom glyphs

/// Chevron-down glyph drawn by hand (used for the dropdown "more" arrows).
struct ChevronDownGlyph: View {
    var color: Color = Palette.subtitleGray
    var lineWidth: CGFloat = 2
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                p.move(to: CGPoint(x: w * 0.2, y: h * 0.35))
                p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.65))
                p.addLine(to: CGPoint(x: w * 0.8, y: h * 0.35))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }
}

/// Plus glyph.
struct PlusGlyph: View {
    var color: Color = Palette.accent
    var lineWidth: CGFloat = 2.4
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                p.move(to: CGPoint(x: w * 0.5, y: h * 0.22))
                p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.78))
                p.move(to: CGPoint(x: w * 0.22, y: h * 0.5))
                p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.5))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
}

/// A hand-drawn star used for favorite toggles.
struct StarGlyph: View {
    var filled: Bool
    var size: CGFloat = 22
    var body: some View {
        Image(systemName: filled ? "star.fill" : "star")
            .font(.system(size: size * 0.7, weight: .semibold))
            .foregroundStyle(filled ? AnyShapeStyle(Palette.superGradient) : AnyShapeStyle(Color.white))
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }
}

// MARK: - Dashed "New" tile

struct DashedNewTile: View {
    var title: String = "Neu"
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .foregroundStyle(Palette.dashedGray)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.35))
                )
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(Palette.accent.opacity(0.12)).frame(width: 54, height: 54)
                    PlusGlyph(color: Palette.accent, lineWidth: 3)
                        .frame(width: 28, height: 28)
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.accent)
            }
        }
    }
}
