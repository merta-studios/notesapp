import SwiftUI

/// The list-layout variant of an item (when the user switches grid → list).
struct ItemListRow: View {
    let item: NoteItem
    @EnvironmentObject var app: AppState
    @ObservedObject var store: NoteStore = .shared
    @State private var showMenu = false
    @State private var confirmDelete = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack(spacing: 16) {
            Button { app.open(item.id) } label: {
                ItemSquareIcon(item: item)
                    .frame(width: 64, height: 64)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1)
                Text(DateFormat.string(item.modifiedAt))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Palette.subtitleGray)
                Text(item.type.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.subtitleGray.opacity(0.8))
            }
            Spacer()

            if item.canBeFavorite {
                Button { store.toggleFavorite(item.id) } label: {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(item.isFavorite ? AnyShapeStyle(Palette.superGradient) : AnyShapeStyle(Palette.subtitleGray))
                }
                .buttonStyle(.plain)
            }

            Button { showMenu = true } label: {
                ChevronDownGlyph(color: Palette.subtitleGray, lineWidth: 2)
                    .frame(width: 16, height: 16)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color(.sRGB, white: 0.92, opacity: 1)))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showMenu, arrowEdge: .top) {
                ItemActionMenu(item: item, confirmDelete: $confirmDelete)
                    .environmentObject(app)
                    .frame(width: 300)
                    .presentationCompactAdaptation(.popover)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.6), lineWidth: 1))
        )
        .hoverLift(scale: 1.01)
        .alert("In den Papierkorb legen?", isPresented: $confirmDelete) {
            Button("Abbrechen", role: .cancel) {}
            Button("In den Papierkorb", role: .destructive) {
                store.moveToTrash(item.id); app.closeTab(item.id)
            }
        } message: {
            Text("„\(item.name)“ wird in den Papierkorb gelegt.")
        }
    }
}
