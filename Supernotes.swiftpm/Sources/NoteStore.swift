import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// The single source of truth for all Supernotes data.
///
/// A shared singleton so every window (Swift Playgrounds / iPadOS can open the
/// app in multiple windows) observes the exact same data. All mutations are
/// persisted to disk immediately (auto-save) and broadcast so a second window
/// showing the same document updates live.
@MainActor
final class NoteStore: ObservableObject {
    static let shared = NoteStore()

    @Published private(set) var items: [NoteItem] = []

    /// Bumped whenever a page's drawing changes on disk, so open canvases in
    /// other windows can reload. Keyed by page id -> revision token.
    @Published private(set) var drawingRevisions: [UUID: Int] = [:]

    private let fileManager = FileManager.default
    private var saveWorkItem: DispatchWorkItem?

    // MARK: - Paths

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var rootURL: URL {
        let url = documentsURL.appendingPathComponent("Supernotes", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private var itemsFileURL: URL { rootURL.appendingPathComponent("items.json") }

    private var drawingsURL: URL {
        let url = rootURL.appendingPathComponent("drawings", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private var assetsURL: URL {
        let url = rootURL.appendingPathComponent("assets", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    // MARK: - Init

    private init() {
        load()
        if items.isEmpty {
            seedSampleContent()
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: itemsFileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([NoteItem].self, from: data) {
            items = decoded
        }
    }

    /// Debounced save to avoid hammering the disk during rapid edits.
    private func scheduleSave() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.saveNow()
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func saveNow() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(items) {
            try? data.write(to: itemsFileURL, options: .atomic)
        }
    }

    // MARK: - Queries

    func item(id: UUID?) -> NoteItem? {
        guard let id else { return nil }
        return items.first { $0.id == id }
    }

    /// Live items (not trashed) inside a given folder.
    func children(of parentID: UUID?) -> [NoteItem] {
        items.filter { $0.parentID == parentID && !$0.isTrashed }
    }

    /// All favorite documents anywhere in the tree (flat, no folders).
    func favorites() -> [NoteItem] {
        items.filter { $0.isFavorite && !$0.isTrashed && $0.canBeFavorite }
    }

    func trashedItems() -> [NoteItem] {
        items.filter { $0.isTrashed }
    }

    /// All folders (used for "move to folder" pickers).
    func allFolders() -> [NoteItem] {
        items.filter { $0.type == .folder && !$0.isTrashed }
    }

    func sorted(_ list: [NoteItem], by order: SortOrder) -> [NoteItem] {
        switch order {
        case .modified:
            return list.sorted { $0.modifiedAt > $1.modifiedAt }
        case .created:
            return list.sorted { $0.createdAt > $1.createdAt }
        case .name:
            return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .type:
            return list.sorted {
                if $0.type.sortRank != $1.type.sortRank { return $0.type.sortRank < $1.type.sortRank }
                return $0.modifiedAt > $1.modifiedAt
            }
        }
    }

    // MARK: - Mutations

    func add(_ item: NoteItem) {
        items.append(item)
        scheduleSave()
    }

    @discardableResult
    func createNotebook(name: String, parentID: UUID?, template: PaperTemplate, pages: [NotePage]? = nil) -> NoteItem {
        let initialPages = pages ?? [NotePage(template: template)]
        let item = NoteItem(type: .notebook, name: name, parentID: parentID, pages: initialPages)
        add(item)
        return item
    }

    @discardableResult
    func createWhiteboard(name: String, parentID: UUID?, template: PaperTemplate) -> NoteItem {
        var wbTemplate = template
        // Whiteboards have no lined style.
        if wbTemplate.style == .lined { wbTemplate.style = .dotted }
        let page = NotePage(template: wbTemplate)
        let item = NoteItem(type: .whiteboard, name: name, parentID: parentID, pages: [page])
        add(item)
        return item
    }

    @discardableResult
    func createFolder(name: String, color: RGBAColor, parentID: UUID?) -> NoteItem {
        let item = NoteItem(type: .folder, name: name, parentID: parentID, folderColor: color)
        add(item)
        return item
    }

    func rename(_ id: UUID, to newName: String) {
        update(id) { $0.name = newName }
    }

    func toggleFavorite(_ id: UUID) {
        guard let item = item(id: id), item.canBeFavorite else { return }
        update(id) { $0.isFavorite.toggle() }
    }

    func setFavorite(_ id: UUID, _ value: Bool) {
        guard let item = item(id: id), item.canBeFavorite else { return }
        update(id) { $0.isFavorite = value }
    }

    /// Move an item to the trash. Folders take their descendants with them.
    func moveToTrash(_ id: UUID) {
        guard let item = item(id: id) else { return }
        if item.type == .folder {
            for child in descendants(of: id) {
                update(child.id) { $0.isTrashed = true }
            }
        }
        update(id) { $0.isTrashed = true }
    }

    func restoreFromTrash(_ id: UUID) {
        update(id) { $0.isTrashed = false }
    }

    func deletePermanently(_ id: UUID) {
        guard let item = item(id: id) else { return }
        // remove drawings + assets for its pages
        for page in item.pages {
            try? fileManager.removeItem(at: drawingURL(for: page.id))
            if let bg = page.backgroundImageFile {
                try? fileManager.removeItem(at: assetsURL.appendingPathComponent(bg))
            }
        }
        items.removeAll { $0.id == id }
        scheduleSave()
    }

    func emptyTrash() {
        for item in trashedItems() { deletePermanently(item.id) }
    }

    func move(_ id: UUID, toFolder parentID: UUID?) {
        // Prevent moving a folder into itself/its descendants.
        if let item = item(id: id), item.type == .folder, let target = parentID {
            if target == id || descendants(of: id).contains(where: { $0.id == target }) { return }
        }
        update(id) { $0.parentID = parentID }
    }

    func setFolderColor(_ id: UUID, _ color: RGBAColor) {
        update(id) { $0.folderColor = color }
    }

    private func descendants(of folderID: UUID) -> [NoteItem] {
        var result: [NoteItem] = []
        let directChildren = items.filter { $0.parentID == folderID }
        for child in directChildren {
            result.append(child)
            if child.type == .folder {
                result.append(contentsOf: descendants(of: child.id))
            }
        }
        return result
    }

    /// Central update helper — always bumps modifiedAt and auto-saves.
    private func update(_ id: UUID, _ mutate: (inout NoteItem) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        var item = items[index]
        mutate(&item)
        item.modifiedAt = Date()
        items[index] = item
        scheduleSave()
    }

    /// Update without touching modifiedAt (e.g. remembering last page).
    func setLastOpenedPage(_ id: UUID, index: Int) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].lastOpenedPageIndex = index
        scheduleSave()
    }

    // MARK: - Pages

    func addPage(to itemID: UUID, page: NotePage, at index: Int) {
        update(itemID) {
            let clamped = max(0, min(index, $0.pages.count))
            $0.pages.insert(page, at: clamped)
        }
    }

    func deletePages(_ pageIDs: Set<UUID>, from itemID: UUID) {
        update(itemID) { item in
            for pid in pageIDs {
                if let p = item.pages.first(where: { $0.id == pid }) {
                    try? self.fileManager.removeItem(at: self.drawingURL(for: p.id))
                }
            }
            item.pages.removeAll { pageIDs.contains($0.id) }
            if item.pages.isEmpty {
                item.pages.append(NotePage(template: .defaultNotebook))
            }
        }
    }

    func movePage(in itemID: UUID, from source: IndexSet, to destination: Int) {
        update(itemID) { $0.pages.move(fromOffsets: source, toOffset: destination) }
    }

    /// Move given pages to another notebook (append at end).
    func movePages(_ pageIDs: [UUID], from sourceID: UUID, to targetID: UUID) {
        guard sourceID != targetID else { return }
        guard let source = item(id: sourceID) else { return }
        let moving = source.pages.filter { pageIDs.contains($0.id) }
        guard !moving.isEmpty else { return }
        update(sourceID) { $0.pages.removeAll { pageIDs.contains($0.id) }
            if $0.pages.isEmpty { $0.pages.append(NotePage(template: .defaultNotebook)) }
        }
        update(targetID) { $0.pages.append(contentsOf: moving) }
    }

    func updatePageTemplate(itemID: UUID, pageID: UUID, template: PaperTemplate) {
        update(itemID) { item in
            if let idx = item.pages.firstIndex(where: { $0.id == pageID }) {
                item.pages[idx].template = template
            }
        }
    }

    // MARK: - Drawing data

    func drawingURL(for pageID: UUID) -> URL {
        drawingsURL.appendingPathComponent("\(pageID.uuidString).drawing")
    }

    func loadDrawingData(for pageID: UUID) -> Data? {
        try? Data(contentsOf: drawingURL(for: pageID))
    }

    /// Persist a page's drawing and notify other windows.
    func saveDrawingData(_ data: Data, for pageID: UUID, in itemID: UUID) {
        try? data.write(to: drawingURL(for: pageID), options: .atomic)
        drawingRevisions[pageID, default: 0] += 1
        // Touch modifiedAt so lists reorder by recency.
        update(itemID) { _ in }
    }

    // MARK: - Assets (imported images / pdf pages)

    func saveAsset(_ data: Data, ext: String) -> String {
        let name = "\(UUID().uuidString).\(ext)"
        try? data.write(to: assetsURL.appendingPathComponent(name), options: .atomic)
        return name
    }

    func assetURL(for file: String) -> URL {
        assetsURL.appendingPathComponent(file)
    }

    #if canImport(UIKit)
    func loadAssetImage(_ file: String?) -> UIImage? {
        guard let file, let data = try? Data(contentsOf: assetURL(for: file)) else { return nil }
        return UIImage(data: data)
    }
    #endif

    // MARK: - Sample content

    private func seedSampleContent() {
        let welcome = NoteItem(
            type: .notebook,
            name: "Willkommen bei Supernotes",
            pages: [
                NotePage(template: PaperTemplate(style: .grid, orientation: .portrait, size: .a4, background: .white)),
                NotePage(template: PaperTemplate(style: .lined, orientation: .portrait, size: .a4, background: .white))
            ]
        )
        let ideas = NoteItem(type: .whiteboard, name: "Ideen Board", isFavorite: true,
                             pages: [NotePage(template: .defaultWhiteboard)])
        let folder = NoteItem(type: .folder, name: "Projekte", folderColor: RGBAColor.folderPalette[0])
        let sketch = NoteItem(type: .notebook, name: "Skizzen", isFavorite: true, parentID: folder.id,
                              pages: [NotePage(template: PaperTemplate(style: .dotted, orientation: .landscape, size: .a4))])
        items = [welcome, ideas, folder, sketch]
        saveNow()
    }
}
