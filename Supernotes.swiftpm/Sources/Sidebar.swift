import SwiftUI

struct Sidebar: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            SupernotesTitle(scale: 1.0)
                .padding(.top, 26)
                .padding(.horizontal, 22)
                .padding(.bottom, 26)

            // Sections
            VStack(spacing: 8) {
                SidebarRow(icon: AnyView(NotebookIcon(accent: Palette.accent)),
                           title: "Dokumente",
                           isSelected: app.sidebarSection == .documents && !app.showingSettings) {
                    app.selectSection(.documents)
                    app.goHome()
                }
                SidebarRow(icon: AnyView(StarIconView()),
                           title: "Favoriten",
                           isSelected: app.sidebarSection == .favorites && !app.showingSettings) {
                    app.selectSection(.favorites)
                    app.goHome()
                }
                SidebarRow(icon: AnyView(GearIconView()),
                           title: "Einstellungen",
                           isSelected: app.showingSettings) {
                    app.showingSettings = true
                }
            }
            .padding(.horizontal, 14)

            Spacer()

            // Small footer / beta badge
            HStack(spacing: 8) {
                Circle().fill(Palette.superGradient).frame(width: 8, height: 8)
                Text("Beta Version")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.subtitleGray)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(width: 268)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 20, x: 8, y: 0)
        )
        .padding(.vertical, 16)
        .padding(.leading, 16)
    }
}

struct SidebarRow: View {
    let icon: AnyView
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                icon.frame(width: 26, height: 26)
                Text(title)
                    .font(.system(size: 17, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? AnyShapeStyle(Palette.accentDeep) : AnyShapeStyle(Color.primary.opacity(0.8)))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Palette.accent.opacity(0.16)) : AnyShapeStyle(Color.white.opacity(hovering ? 0.4 : 0.0)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Palette.accent.opacity(isSelected ? 0.35 : 0), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering ? 1.02 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: hovering)
        .onHover { hovering = $0 }
    }
}

// Small custom icons for sidebar rows
struct StarIconView: View {
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Palette.superGradient)
    }
}

struct GearIconView: View {
    var body: some View {
        Image(systemName: "gearshape.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Palette.accent)
    }
}
