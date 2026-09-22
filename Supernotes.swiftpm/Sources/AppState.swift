import SwiftUI

/// Per-window UI state. Data lives in NoteStore.shared (shared across windows);
/// this only tracks what THIS window is showing: open tabs, selection, whether
/// we're on the home screen or inside a document.
@MainActor
final class AppState: ObservableObject {
    enum Mode { case home, document }

    @Published var mode: Mode = .home

    // Home screen
    @Published var sidebarOpen: Bool = true
    @Published var sidebarSection: SidebarSection = .documents
    @Published var currentFolderID: UUID? = nil          // navigation into folders
    @Published var folderPath: [UUID] = []               // breadcrumb stack
    @Published var sortOrder: SortOrder = .modified
    @Published var layout: ContentLayout = .grid

    // Global overlays
    @Published var showingSettings: Bool = false
    @Published var showingNewPicker: Bool = false

    // Tabs
    @Published var openTabs: [UUID] = []
    @Published var selectedTabID: UUID?

    /// If this window was launched as a dedicated single-document window.
    var isDedicatedWindow: Bool = false

    // MARK: - Tab management

    func open(_ itemID: UUID) {
        guard let item = NoteStore.shared.item(id: itemID) else { return }
        if item.type == .folder {
            navigateInto(itemID)
            return
        }
        if !openTabs.contains(itemID) {
            openTabs.append(itemID)
        }
        selectedTabID = itemID
        mode = .document
    }

    func closeTab(_ itemID: UUID) {
        guard let idx = openTabs.firstIndex(of: itemID) else { return }
        openTabs.remove(at: idx)
        if selectedTabID == itemID {
            if openTabs.isEmpty {
                selectedTabID = nil
                mode = .home
            } else {
                selectedTabID = openTabs[min(idx, openTabs.count - 1)]
            }
        }
    }

    func goHome() {
        mode = .home
    }

    // MARK: - Folder navigation

    func navigateInto(_ folderID: UUID) {
        folderPath.append(folderID)
        currentFolderID = folderID
    }

    func navigateToRoot() {
        folderPath.removeAll()
        currentFolderID = nil
    }

    func navigateTo(depth: Int) {
        if depth < 0 {
            navigateToRoot()
        } else if depth < folderPath.count {
            folderPath = Array(folderPath.prefix(depth + 1))
            currentFolderID = folderPath.last
        }
    }

    func selectSection(_ section: SidebarSection) {
        sidebarSection = section
        navigateToRoot()
    }
}

/// Value type used to open a document in a brand new iPad window.
struct DocumentWindowValue: Hashable, Codable {
    var itemID: UUID
    var pageID: UUID?   // optional: open at a specific page
}
