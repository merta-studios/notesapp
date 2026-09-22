import SwiftUI

/// Sheet for adding a page to a notebook: where to insert, plus full paper
/// template config, plus a quick "same as current page" option.
struct AddPageSheet: View {
    let item: NoteItem
    let currentPageIndex: Int
    var onDone: (Int) -> Void   // returns the index the new page was inserted at
    @ObservedObject var store: NoteStore = .shared
    @Environment(\.dismiss) private var dismiss

    enum Position: String, CaseIterable, Identifiable {
        case before, after, last
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .before: return "Vor der aktuellen Seite"
            case .after:  return "Nach der aktuellen Seite"
            case .last:   return "Letzte Seite"
            }
        }
    }

    @State private var position: Position = .after
    @State private var template = PaperTemplate.defaultNotebook

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Quick option: template of current page
                    Button {
                        if let current = store.item(id: item.id)?.pages[safe: currentPageIndex] {
                            template = current.template
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Palette.superPink)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Vorlage von aktueller Seite")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.primary)
                                Text("Schnellauswahl")
                                    .font(.system(size: 12)).foregroundStyle(Palette.subtitleGray)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.superPink.opacity(0.1)))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.superPink.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Position").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Palette.subtitleGray)
                        VStack(spacing: 8) {
                            ForEach(Position.allCases) { p in
                                Button { position = p } label: {
                                    HStack {
                                        Image(systemName: position == p ? "largecircle.fill.circle" : "circle")
                                            .foregroundStyle(Palette.accent)
                                        Text(p.displayName).foregroundStyle(Color.primary)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.5)))
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    PaperTemplateChooser(template: $template, allowLined: item.type == .notebook)
                }
                .padding(24)
            }
            .navigationTitle("Seite hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        let count = store.item(id: item.id)?.pages.count ?? 0
                        let insertIndex: Int
                        switch position {
                        case .before: insertIndex = currentPageIndex
                        case .after:  insertIndex = currentPageIndex + 1
                        case .last:   insertIndex = count
                        }
                        store.addPage(to: item.id, page: NotePage(template: template), at: insertIndex)
                        onDone(insertIndex)
                        dismiss()
                    }.fontWeight(.bold)
                }
            }
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
