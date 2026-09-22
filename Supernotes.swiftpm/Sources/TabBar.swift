import SwiftUI

/// The top blue bar full of open tabs. A square home button on the far left,
/// then the tabs. Tabs grow up to half the screen width when there's room,
/// shrink to a minimum width when crowded, and become horizontally scrollable
/// when even the minimum no longer fits.
struct DocumentTabBar: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var store: NoteStore = .shared
    var readOnly: Bool

    private let minTabWidth: CGFloat = 130
    private let homeButtonWidth: CGFloat = 54
    private let spacing: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let available = geo.size.width - homeButtonWidth - spacing * 2 - 16
            let count = max(app.openTabs.count, 1)
            let idealMax = geo.size.width * 0.5
            let evenWidth = (available - spacing * CGFloat(count - 1)) / CGFloat(count)
            let needsScroll = evenWidth < minTabWidth
            let tabWidth = needsScroll ? minTabWidth : min(idealMax, max(minTabWidth, evenWidth))

            HStack(spacing: spacing) {
                // Home button
                Button { app.goHome() } label: {
                    HouseIcon(color: .white)
                        .frame(width: 24, height: 24)
                }
                .frame(width: homeButtonWidth, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                )
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                .buttonStyle(HomeButtonStyle())

                if needsScroll {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing) {
                            tabRow(width: tabWidth)
                        }
                    }
                } else {
                    HStack(spacing: spacing) {
                        tabRow(width: tabWidth)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 60)
        .background(
            (readOnly ? AnyShapeStyle(Palette.readOnlyBar) : AnyShapeStyle(
                LinearGradient(colors: [Palette.titleBar, Palette.accentDeep],
                               startPoint: .leading, endPoint: .trailing)))
        )
        .overlay(alignment: .center) {
            if readOnly {
                Text("Nur lesen")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private func tabRow(width: CGFloat) -> some View {
        ForEach(app.openTabs, id: \.self) { tabID in
            if let item = store.item(id: tabID) {
                TabChip(item: item, width: width,
                        isSelected: app.selectedTabID == tabID,
                        readOnly: readOnly)
                    .environmentObject(app)
            }
        }
    }
}

struct HomeButtonStyle: ButtonStyle {
    @State private var hovering = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.9 : (hovering ? 1.06 : 1))
            .brightness(hovering ? 0.08 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: hovering)
            .onHover { hovering = $0 }
    }
}

struct TabChip: View {
    let item: NoteItem
    let width: CGFloat
    let isSelected: Bool
    let readOnly: Bool
    @EnvironmentObject var app: AppState
    @ObservedObject var store: NoteStore = .shared
    @State private var hovering = false
    @State private var showMenu = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack(spacing: 6) {
            // dropdown menu
            Button { showMenu = true } label: {
                ChevronDownGlyph(color: isSelected ? Palette.accentDeep : .white, lineWidth: 2)
                    .frame(width: 12, height: 12)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showMenu, arrowEdge: .bottom) {
                TabActionMenu(item: item).environmentObject(app)
                    .frame(width: 290)
                    .presentationCompactAdaptation(.popover)
            }

            Text(item.name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Palette.accentDeep : .white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // close (no confirmation, just closes tab)
            Button { app.closeTab(item.id) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? Palette.accentDeep.opacity(0.7) : Color.white.opacity(0.85))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.white.opacity(hovering ? 0.001 : 0)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(width: width, height: 44)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.white.opacity(hovering ? 0.22 : 0.12)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(Color.white.opacity(isSelected ? 0 : 0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isSelected ? 0.15 : 0), radius: 6, y: 2)
        .contentShape(Rectangle())
        .onTapGesture { app.selectedTabID = item.id }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
        .onHover { hovering = $0 }
    }
}

/// Dropdown from a tab: rename + open in new window + favorite.
struct TabActionMenu: View {
    let item: NoteItem
    @EnvironmentObject var app: AppState
    @ObservedObject var store: NoteStore = .shared
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Name").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Palette.subtitleGray)
                TextField("Name", text: $editedName)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .onSubmit {
                        let t = editedName.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty { store.rename(item.id, to: t) }
                    }
            }
            Divider()
            MenuButton(icon: "plus.rectangle.on.rectangle", title: "In neuem Fenster öffnen") {
                dismiss()
                openWindow(id: "document", value: DocumentWindowValue(itemID: item.id, pageID: nil))
            }
            if item.canBeFavorite {
                MenuButton(icon: item.isFavorite ? "star.slash" : "star.fill",
                           title: item.isFavorite ? "Favorit aus" : "Favorit ein") {
                    store.toggleFavorite(item.id); dismiss()
                }
            }
            MenuButton(icon: "xmark.circle", title: "Tab schließen") {
                app.closeTab(item.id); dismiss()
            }
        }
        .padding(16)
        .onAppear { editedName = item.name }
    }
}
