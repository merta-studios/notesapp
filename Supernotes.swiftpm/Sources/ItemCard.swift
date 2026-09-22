import SwiftUI

/// A single item card in the grid: square icon (with star), blue title,
/// gray modified date, and a gray dropdown button revealing actions.
struct ItemGridCard: View {
    let item: NoteItem
    @EnvironmentObject var app: AppState
    @ObservedObject var store: NoteStore = .shared

    @State private var showMenu = false
    @State private var confirmDelete = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Button {
                    app.open(item.id)
                } label: {
                    ItemSquareIcon(item: item)
                }
                .buttonStyle(.plain)

                // Favorite star (not for folders)
                if item.canBeFavorite {
                    Button {
                        store.toggleFavorite(item.id)
                    } label: {
                        StarGlyph(filled: item.isFavorite, size: 26)
                            .padding(8)
                            .background(Circle().fill(.ultraThinMaterial))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            }
            .hoverLift()

            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.accent)
                        .lineLimit(1)
                    Text(DateFormat.string(item.modifiedAt))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Palette.subtitleGray)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Button {
                    showMenu = true
                } label: {
                    ChevronDownGlyph(color: Palette.subtitleGray, lineWidth: 2)
                        .frame(width: 16, height: 16)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color(.sRGB, white: 0.92, opacity: 1)))
                        .overlay(Circle().strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showMenu, arrowEdge: .top) {
                    ItemActionMenu(item: item, confirmDelete: $confirmDelete)
                        .environmentObject(app)
                        .frame(width: 300)
                        .presentationCompactAdaptation(.popover)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.white.opacity(0.6), lineWidth: 1))
        )
        .alert("In den Papierkorb legen?", isPresented: $confirmDelete) {
            Button("Abbrechen", role: .cancel) {}
            Button("In den Papierkorb", role: .destructive) {
                store.moveToTrash(item.id)
                app.closeTab(item.id)
            }
        } message: {
            Text("„\(item.name)“ wird in den Papierkorb gelegt.")
        }
    }
}

/// The dropdown action menu shown from the chevron button on a card.
struct ItemActionMenu: View {
    let item: NoteItem
    @Binding var confirmDelete: Bool
    @EnvironmentObject var app: AppState
    @ObservedObject var store: NoteStore = .shared
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Rename field
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.subtitleGray)
                TextField("Name", text: $editedName)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .onSubmit { commitName() }
            }

            Divider()

            MenuButton(icon: "book.pages", title: "Öffnen") {
                dismiss(); app.open(item.id)
            }
            if item.type != .folder {
                MenuButton(icon: "plus.rectangle.on.rectangle", title: "In neuem Fenster öffnen") {
                    dismiss()
                    openWindow(id: "document", value: DocumentWindowValue(itemID: item.id, pageID: nil))
                }
                MenuButton(icon: item.isFavorite ? "star.slash" : "star.fill",
                           title: item.isFavorite ? "Favorit aus" : "Favorit ein") {
                    store.toggleFavorite(item.id); dismiss()
                }
            }
            MenuButton(icon: "trash", title: "In den Papierkorb legen", role: .destructive) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { confirmDelete = true }
            }
        }
        .padding(16)
        .onAppear { editedName = item.name }
    }

    private func commitName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { store.rename(item.id, to: trimmed) }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    var role: ButtonRole? = nil
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 22)
                    .foregroundStyle(role == .destructive ? AnyShapeStyle(Color.red) : AnyShapeStyle(Palette.accent))
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(role == .destructive ? AnyShapeStyle(Color.red) : AnyShapeStyle(Color.primary))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(hovering ? 0.06 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
