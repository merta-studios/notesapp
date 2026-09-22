import SwiftUI

/// A one-of-a-kind wordmark for "Supernotes".
///
/// "super" is set in a bold rounded face with a vivid pink→orange gradient, a
/// little upward tilt and a soft glow, plus a hand-drawn sparkle — clearly the
/// hero of the logo. "notes" follows in a calmer inked blue-violet gradient.
struct SupernotesTitle: View {
    var scale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 2 * scale) {
            HStack(alignment: .firstTextBaseline, spacing: 1 * scale) {
                ZStack(alignment: .topTrailing) {
                    Text("super")
                        .font(.system(size: 34 * scale, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.superGradient)
                        .shadow(color: Palette.superPink.opacity(0.45), radius: 8 * scale, x: 0, y: 3 * scale)
                        .rotationEffect(.degrees(-4))
                        .overlay(
                            // glossy highlight sweep across the word
                            Text("super")
                                .font(.system(size: 34 * scale, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [.white.opacity(0.7), .clear],
                                                   startPoint: .top, endPoint: .center)
                                )
                                .rotationEffect(.degrees(-4))
                                .blendMode(.screen)
                        )
                    Sparkle()
                        .frame(width: 14 * scale, height: 14 * scale)
                        .offset(x: 8 * scale, y: -8 * scale)
                }
                Text("notes")
                    .font(.system(size: 30 * scale, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.titleGradient)
            }
            // underline swoosh under "super"
            SwooshUnderline()
                .stroke(Palette.superGradient, style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round))
                .frame(width: 96 * scale, height: 8 * scale)
                .offset(x: 2 * scale)
        }
        .accessibilityElement()
        .accessibilityLabel("Supernotes")
    }
}

private struct SwooshUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY + rect.height))
        return p
    }
}

/// A tiny four-point sparkle drawn by hand.
struct Sparkle: View {
    var color: Color = .white
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                p.move(to: CGPoint(x: w * 0.5, y: 0))
                p.addQuadCurve(to: CGPoint(x: w, y: h * 0.5), control: CGPoint(x: w * 0.58, y: h * 0.42))
                p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 0.58, y: h * 0.58))
                p.addQuadCurve(to: CGPoint(x: 0, y: h * 0.5), control: CGPoint(x: w * 0.42, y: h * 0.58))
                p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: w * 0.42, y: h * 0.42))
            }
            .fill(
                LinearGradient(colors: [.white, Palette.superOrange],
                               startPoint: .top, endPoint: .bottom)
            )
            .shadow(color: .white.opacity(0.8), radius: 3)
        }
    }
}
