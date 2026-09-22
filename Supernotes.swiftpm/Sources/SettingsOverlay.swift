import SwiftUI

/// A large panel that appears over everything (not a separate right-hand page).
struct SettingsOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Dimmed backdrop; tap to dismiss.
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                        Text("Einstellungen")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.accentDeep)
                    }
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .buttonStyle(CircleIconButtonStyle(size: 40))
                }
                .padding(24)

                Divider().opacity(0.4)

                // Body — beta placeholder
                VStack(spacing: 20) {
                    Spacer()
                    ZStack {
                        Circle().fill(Palette.superGradient.opacity(0.15)).frame(width: 120, height: 120)
                        Sparkle().frame(width: 54, height: 54)
                    }
                    Text("Beta Version")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.accentDeep)
                    Text("Hier gibt es noch nichts einzustellen.\nWir bauen Supernotes Stück für Stück weiter aus.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.subtitleGray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(30)
            }
            .frame(maxWidth: 720, maxHeight: 560)
            .liquidGlass(cornerRadius: 34)
            .padding(40)
        }
    }
}
