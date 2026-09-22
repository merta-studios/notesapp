import SwiftUI

// MARK: - Palette

enum Palette {
    static let accent = Color(.sRGB, red: 0.20, green: 0.53, blue: 0.96)
    static let accentDeep = Color(.sRGB, red: 0.10, green: 0.36, blue: 0.86)
    static let superPink = Color(.sRGB, red: 0.98, green: 0.36, blue: 0.62)
    static let superOrange = Color(.sRGB, red: 0.99, green: 0.62, blue: 0.28)
    static let titleBar = Color(.sRGB, red: 0.16, green: 0.47, blue: 0.94)
    static let readOnlyBar = Color(.sRGB, red: 0.40, green: 0.42, blue: 0.46)
    static let subtitleGray = Color(.sRGB, red: 0.56, green: 0.58, blue: 0.62)
    static let dashedGray = Color(.sRGB, red: 0.66, green: 0.68, blue: 0.72)

    static let superGradient = LinearGradient(
        colors: [superPink, superOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let titleGradient = LinearGradient(
        colors: [Color(.sRGB, red: 0.20, green: 0.53, blue: 0.96),
                 Color(.sRGB, red: 0.44, green: 0.40, blue: 0.96)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Liquid Glass

/// A reusable "liquid glass" surface: translucent material, soft inner light,
/// subtle border and depth shadow. Used throughout for panels, popovers, cards.
struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat = 22
    var strokeOpacity: Double = 0.5
    var elevated: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(strokeOpacity), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(elevated ? 0.18 : 0.08),
                    radius: elevated ? 22 : 8, x: 0, y: elevated ? 12 : 4)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 22, strokeOpacity: Double = 0.5, elevated: Bool = true) -> some View {
        modifier(LiquidGlass(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity, elevated: elevated))
    }
}

// MARK: - Hoverable / pressable button style

/// A button style giving every button a smooth hover highlight (great with a
/// trackpad or the Apple Pencil hover on iPad) and a gentle press animation.
struct GlassButtonStyle: ButtonStyle {
    var tint: Color = Palette.accent
    var filled: Bool = false
    var cornerRadius: CGFloat = 14
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(.ultraThinMaterial))
                    if !filled {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(hovering ? 0.18 : 0.0))
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(hovering ? 0.12 : 0.0))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(filled ? 0.25 : 0.4), lineWidth: 1)
            )
            .foregroundStyle(filled ? AnyShapeStyle(Color.white) : AnyShapeStyle(tint))
            .scaleEffect(configuration.isPressed ? 0.96 : (hovering ? 1.02 : 1.0))
            .shadow(color: tint.opacity(filled && hovering ? 0.4 : 0), radius: 10, y: 4)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: hovering)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
            .onHover { hovering = $0 }
    }
}

/// Circular icon button with hover glow. Used all over the toolbars.
struct CircleIconButtonStyle: ButtonStyle {
    var tint: Color = Palette.accent
    var size: CGFloat = 40
    var filled: Bool = false
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(
                ZStack {
                    Circle().fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(.ultraThinMaterial))
                    Circle().fill((filled ? Color.white : tint).opacity(hovering ? (filled ? 0.15 : 0.16) : 0))
                }
            )
            .overlay(Circle().strokeBorder(Color.white.opacity(filled ? 0.3 : 0.45), lineWidth: 1))
            .foregroundStyle(filled ? AnyShapeStyle(Color.white) : AnyShapeStyle(tint))
            .scaleEffect(configuration.isPressed ? 0.92 : (hovering ? 1.06 : 1.0))
            .shadow(color: tint.opacity(hovering ? 0.35 : 0.12), radius: hovering ? 10 : 4, y: 3)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: hovering)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
            .onHover { hovering = $0 }
    }
}

// MARK: - Hover scale for arbitrary views (e.g. grid cards)

struct HoverLift: ViewModifier {
    @State private var hovering = false
    var scale: CGFloat = 1.03
    func body(content: Content) -> some View {
        content
            .scaleEffect(hovering ? scale : 1.0)
            .shadow(color: Color.black.opacity(hovering ? 0.20 : 0.10),
                    radius: hovering ? 20 : 10, y: hovering ? 12 : 6)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
            .onHover { hovering = $0 }
    }
}

extension View {
    func hoverLift(scale: CGFloat = 1.03) -> some View { modifier(HoverLift(scale: scale)) }
}

// MARK: - App background

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.sRGB, red: 0.90, green: 0.94, blue: 1.0),
                    Color(.sRGB, red: 0.96, green: 0.93, blue: 1.0),
                    Color(.sRGB, red: 0.92, green: 0.97, blue: 0.98)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // Soft floating light blobs for a lively glassy backdrop.
            GeometryReader { geo in
                ZStack {
                    Circle().fill(Palette.superPink.opacity(0.18))
                        .frame(width: geo.size.width * 0.6)
                        .blur(radius: 90)
                        .offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.15)
                    Circle().fill(Palette.accent.opacity(0.18))
                        .frame(width: geo.size.width * 0.55)
                        .blur(radius: 90)
                        .offset(x: geo.size.width * 0.35, y: geo.size.height * 0.5)
                    Circle().fill(Palette.superOrange.opacity(0.12))
                        .frame(width: geo.size.width * 0.4)
                        .blur(radius: 80)
                        .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.3)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Date formatting

enum DateFormat {
    static let display: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "dd.MM.yyyy, HH:mm"
        return f
    }()

    static func string(_ date: Date) -> String { display.string(from: date) }
}
