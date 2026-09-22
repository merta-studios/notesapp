import SwiftUI

/// A rich editor for a PaperTemplate: style, orientation, size (with custom
/// pixels), and background color (with custom color). Used at creation time and
/// when adding pages. `allowLined` is false for whiteboards.
struct PaperTemplateChooser: View {
    @Binding var template: PaperTemplate
    var allowLined: Bool = true
    var showOrientation: Bool = true
    var showSize: Bool = true

    @State private var customWidth: String = "800"
    @State private var customHeight: String = "1000"
    @State private var customColor: Color = .white
    @State private var usingCustomSize = false
    @State private var usingCustomColor = false

    private var styles: [PaperStyle] {
        allowLined ? PaperStyle.allCases : PaperStyle.allCases.filter { $0 != .lined }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Style
            section("Papier") {
                HStack(spacing: 10) {
                    ForEach(styles) { style in
                        stylePreview(style)
                    }
                }
            }

            if showOrientation {
                section("Ausrichtung") {
                    HStack(spacing: 10) {
                        ForEach(PaperOrientation.allCases) { o in
                            chip(o.displayName, selected: template.orientation == o) {
                                template.orientation = o
                            }
                        }
                    }
                }
            }

            if showSize {
                section("Größe") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(PaperSize.standardCases, id: \.displayName) { size in
                                chip(size.displayName, selected: !usingCustomSize && template.size.displayName == size.displayName) {
                                    usingCustomSize = false
                                    template.size = size
                                }
                            }
                            chip("Eigene", selected: usingCustomSize) {
                                usingCustomSize = true
                                applyCustomSize()
                            }
                        }
                        if usingCustomSize {
                            HStack(spacing: 8) {
                                pixelField("Breite", text: $customWidth)
                                Text("×").foregroundStyle(Palette.subtitleGray)
                                pixelField("Höhe", text: $customHeight)
                                Text("px").foregroundStyle(Palette.subtitleGray)
                            }
                            .onChange(of: customWidth) { _, _ in applyCustomSize() }
                            .onChange(of: customHeight) { _, _ in applyCustomSize() }
                        }
                    }
                }
            }

            // Background color
            section("Hintergrund") {
                HStack(spacing: 10) {
                    colorChip(.white, label: "Weiß")
                    colorChip(.black, label: "Schwarz")
                    colorChip(.yellow, label: "Gelb")
                    // custom
                    ColorPicker("", selection: $customColor, supportsOpacity: false)
                        .labelsHidden()
                        .scaleEffect(1.1)
                        .onChange(of: customColor) { _, newValue in
                            usingCustomColor = true
                            template.background = RGBAColor(UIColor(newValue))
                        }
                        .overlay(alignment: .bottom) {
                            Text("Eigene").font(.system(size: 11, weight: .medium)).foregroundStyle(Palette.subtitleGray).offset(y: 18)
                        }
                }
            }
        }
        .onAppear {
            if case .custom = template.size { usingCustomSize = true }
        }
    }

    // MARK: components

    @ViewBuilder private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.subtitleGray)
            content()
        }
    }

    private func stylePreview(_ style: PaperStyle) -> some View {
        let selected = template.style == style
        return Button { template.style = style } label: {
            VStack(spacing: 6) {
                PaperBackgroundView(template: PaperTemplate(style: style, background: .white))
                    .frame(width: 54, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? Palette.accent : Color.black.opacity(0.1), lineWidth: selected ? 2.5 : 1))
                Text(style.displayName).font(.system(size: 12, weight: selected ? .bold : .regular, design: .rounded))
                    .foregroundStyle(selected ? Palette.accent : Color.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: selected ? .bold : .medium, design: .rounded))
                .foregroundStyle(selected ? AnyShapeStyle(Color.white) : AnyShapeStyle(Palette.accent))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 11).fill(selected ? AnyShapeStyle(Palette.accent) : AnyShapeStyle(Color.white.opacity(0.6))))
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(Palette.accent.opacity(selected ? 0 : 0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func colorChip(_ rgba: RGBAColor, label: String) -> some View {
        let selected = !usingCustomColor && template.background == rgba
        return Button {
            usingCustomColor = false
            template.background = rgba
        } label: {
            VStack(spacing: 5) {
                Circle().fill(rgba.color)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(selected ? Palette.accent : Color.black.opacity(0.15), lineWidth: selected ? 3 : 1))
                Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(Palette.subtitleGray)
            }
        }
        .buttonStyle(.plain)
    }

    private func pixelField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad)
            .frame(width: 70)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
    }

    private func applyCustomSize() {
        let w = Double(customWidth) ?? 800
        let h = Double(customHeight) ?? 1000
        template.size = .custom(width: max(100, w), height: max(100, h))
    }
}
