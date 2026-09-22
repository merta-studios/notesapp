import SwiftUI

// MARK: - Item Type

/// The three fundamental kinds of things Supernotes can store.
/// Everything the user "creates" (photo import, scan, quick note …) ultimately
/// collapses into one of these three types.
enum ItemType: String, Codable, CaseIterable, Identifiable {
    case notebook
    case whiteboard
    case folder

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notebook:   return "Notizbuch"
        case .whiteboard: return "Whiteboard"
        case .folder:     return "Ordner"
        }
    }

    /// Used by the "Typ" sort order.
    var sortRank: Int {
        switch self {
        case .folder:     return 0
        case .notebook:   return 1
        case .whiteboard: return 2
        }
    }
}

// MARK: - Codable Color

/// A small RGBA container so we can persist SwiftUI colors as JSON.
struct RGBAColor: Codable, Equatable, Hashable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }

    #if canImport(UIKit)
    var uiColor: UIColor { UIColor(red: r, green: g, blue: b, alpha: a) }

    init(_ uiColor: UIColor) {
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        uiColor.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        self.init(r: Double(rr), g: Double(gg), b: Double(bb), a: Double(aa))
    }
    #endif

    static let white  = RGBAColor(r: 1, g: 1, b: 1)
    static let black  = RGBAColor(r: 0.09, g: 0.09, b: 0.10)
    static let yellow = RGBAColor(r: 0.99, g: 0.96, b: 0.80)

    // A pleasant palette used for folder colors.
    static let folderPalette: [RGBAColor] = [
        RGBAColor(r: 0.20, g: 0.53, b: 0.96), // blue
        RGBAColor(r: 0.35, g: 0.78, b: 0.55), // green
        RGBAColor(r: 0.98, g: 0.74, b: 0.28), // amber
        RGBAColor(r: 0.96, g: 0.45, b: 0.42), // red
        RGBAColor(r: 0.72, g: 0.48, b: 0.94), // purple
        RGBAColor(r: 0.36, g: 0.80, b: 0.86), // teal
        RGBAColor(r: 0.98, g: 0.58, b: 0.35), // orange
        RGBAColor(r: 0.60, g: 0.63, b: 0.70)  // slate
    ]
}

// MARK: - Paper Template

enum PaperStyle: String, Codable, CaseIterable, Identifiable {
    case grid    // kariert
    case lined   // liniert
    case dotted  // gepunktet
    case blank   // leer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .grid:   return "Kariert"
        case .lined:  return "Liniert"
        case .dotted: return "Gepunktet"
        case .blank:  return "Leer"
        }
    }
}

enum PaperOrientation: String, Codable, CaseIterable, Identifiable {
    case portrait   // Hochformat
    case landscape  // Querformat

    var id: String { rawValue }
    var displayName: String { self == .portrait ? "Hochformat" : "Querformat" }
}

/// Standard paper sizes plus custom. Base dimensions are in points at portrait.
enum PaperSize: Codable, Equatable, Hashable {
    case a3, a4, a5, a6
    case custom(width: Double, height: Double)

    var displayName: String {
        switch self {
        case .a3: return "A3"
        case .a4: return "A4"
        case .a5: return "A5"
        case .a6: return "A6"
        case .custom: return "Eigene"
        }
    }

    /// Portrait dimensions in points (scaled versions of ISO 216 mm).
    var portraitSize: CGSize {
        switch self {
        case .a3: return CGSize(width: 842, height: 1191)
        case .a4: return CGSize(width: 595, height: 842)
        case .a5: return CGSize(width: 420, height: 595)
        case .a6: return CGSize(width: 298, height: 420)
        case .custom(let w, let h): return CGSize(width: w, height: h)
        }
    }

    static let standardCases: [PaperSize] = [.a3, .a4, .a5, .a6]
}

/// The full definition of a page's paper: look, orientation, dimensions, color.
struct PaperTemplate: Codable, Equatable, Hashable {
    var style: PaperStyle
    var orientation: PaperOrientation
    var size: PaperSize
    var background: RGBAColor

    init(style: PaperStyle = .grid,
         orientation: PaperOrientation = .portrait,
         size: PaperSize = .a4,
         background: RGBAColor = .white) {
        self.style = style
        self.orientation = orientation
        self.size = size
        self.background = background
    }

    /// The actual point-size of the page respecting orientation.
    var pageSize: CGSize {
        let base = size.portraitSize
        switch orientation {
        case .portrait:  return base
        case .landscape: return CGSize(width: base.height, height: base.width)
        }
    }

    static let defaultNotebook = PaperTemplate(style: .grid, orientation: .portrait, size: .a4, background: .white)
    static let defaultWhiteboard = PaperTemplate(style: .dotted, orientation: .landscape, size: .a3, background: .white)
}

// MARK: - Page

/// A single page inside a notebook (or the single infinite page of a whiteboard).
struct NotePage: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var template: PaperTemplate
    /// Optional imported background (photo / scanned page / rendered PDF page).
    /// Stored as a filename relative to the item's asset folder.
    var backgroundImageFile: String?

    init(id: UUID = UUID(),
         template: PaperTemplate = .defaultNotebook,
         backgroundImageFile: String? = nil) {
        self.id = id
        self.template = template
        self.backgroundImageFile = backgroundImageFile
    }

    /// Filename for this page's PencilKit drawing data.
    var drawingFile: String { "\(id.uuidString).drawing" }
}

// MARK: - Note Item

/// The top-level object stored in Supernotes.
struct NoteItem: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var type: ItemType
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    var isFavorite: Bool
    var isTrashed: Bool
    /// Which folder this item lives in. `nil` == root.
    var parentID: UUID?

    // Folder-specific
    var folderColor: RGBAColor?

    // Notebook / whiteboard specific
    var pages: [NotePage]
    /// The page index the user was last viewing (restored when reopening).
    var lastOpenedPageIndex: Int

    init(id: UUID = UUID(),
         type: ItemType,
         name: String,
         createdAt: Date = Date(),
         modifiedAt: Date = Date(),
         isFavorite: Bool = false,
         isTrashed: Bool = false,
         parentID: UUID? = nil,
         folderColor: RGBAColor? = nil,
         pages: [NotePage] = [],
         lastOpenedPageIndex: Int = 0) {
        self.id = id
        self.type = type
        self.name = name
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isFavorite = isFavorite
        self.isTrashed = isTrashed
        self.parentID = parentID
        self.folderColor = folderColor
        self.pages = pages
        self.lastOpenedPageIndex = lastOpenedPageIndex
    }

    var canBeFavorite: Bool { type != .folder }

    static func == (lhs: NoteItem, rhs: NoteItem) -> Bool { lhs.id == rhs.id && lhs.modifiedAt == rhs.modifiedAt && lhs.pages == rhs.pages && lhs.name == rhs.name && lhs.isFavorite == rhs.isFavorite && lhs.parentID == rhs.parentID }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Sorting

enum SortOrder: String, CaseIterable, Identifiable {
    case modified   // Letztes Änderungsdatum (default)
    case name       // Name
    case type       // Typ
    case created    // Letztes Erstelldatum

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .modified: return "Letztes Änderungsdatum"
        case .name:     return "Name"
        case .type:     return "Typ"
        case .created:  return "Letztes Erstelldatum"
        }
    }
}

enum ContentLayout: String {
    case grid
    case list
}

// MARK: - Sidebar Selection

enum SidebarSection: String {
    case documents   // Dokumente
    case favorites   // Favoriten
}
