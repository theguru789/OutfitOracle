//
//  WardrobeItem.swift
//  OutfitOracle
//

import SwiftData
import SwiftUI

@Model
class WardrobeItem {
    var id: UUID
    @Attribute(.externalStorage) var croppedImageData: Data
    var category: String          // raw detector class, e.g. "long_sleeve_top"
    var color: String             // one of Vocabulary.colors
    var pattern: String
    var styleTag: String
    var fabricType: String
    var dateAdded: Date

    // Added for the outfit engine / reuse tracking (defaults keep old stores migrating)
    var roleRaw: String = GarmentRole.top.rawValue
    var name: String = ""
    var colorHex: String = "#8E8E8E"
    var wearCount: Int = 0
    var lastWorn: Date? = nil
    var isArchived: Bool = false
    /// Garment with the background removed (PNG with transparency), used for
    /// outfit pictures. Filled in after saving; nil until then / if it fails.
    @Attribute(.externalStorage) var cutoutImageData: Data? = nil

    init(
        croppedImageData: Data,
        category: String,
        role: GarmentRole? = nil,
        color: String = "unknown",
        colorHex: String? = nil,
        pattern: String = "unknown",
        styleTag: String = "unknown",
        fabricType: String = "unknown",
        name: String? = nil
    ) {
        self.id              = UUID()
        self.croppedImageData = croppedImageData
        self.category        = category
        self.color           = color
        self.pattern         = pattern
        self.styleTag        = styleTag
        self.fabricType      = fabricType
        self.dateAdded       = Date()
        let resolvedRole     = role ?? GarmentRole(detectorLabel: category)
        self.roleRaw         = resolvedRole.rawValue
        self.colorHex        = colorHex ?? Vocabulary.hex(for: color)
        self.name            = name ?? WardrobeItem.defaultName(color: color, fabric: fabricType, role: resolvedRole)
    }

    var role: GarmentRole {
        get { GarmentRole(rawValue: roleRaw) ?? .top }
        set { roleRaw = newValue.rawValue }
    }

    // Convenience: UIImage from stored data
    var croppedImage: UIImage? {
        UIImage(data: croppedImageData)
    }

    /// Background-removed garment if available, otherwise the cropped photo
    var cutoutImage: UIImage? {
        cutoutImageData.flatMap(UIImage.init(data:)) ?? croppedImage
    }

    // Human-readable attribute summary
    var attributeSummary: String {
        [color, pattern, fabricType]
            .filter { $0 != "unknown" }
            .joined(separator: " · ")
    }

    /// Days since last worn (or since added, if never worn)
    var daysSinceWorn: Int {
        let since = lastWorn ?? dateAdded
        return Calendar.current.dateComponents([.day], from: since, to: Date()).day ?? 0
    }

    /// "Forgotten" = not worn in 30+ days — the Oracle nudges these back into rotation
    var isForgotten: Bool { daysSinceWorn >= 30 }

    func markWorn(on date: Date = Date()) {
        wearCount += 1
        lastWorn = date
    }

    static func defaultName(color: String, fabric: String, role: GarmentRole) -> String {
        [color, fabric, role.singular]
            .filter { $0 != "unknown" }
            .joined(separator: " ")
            .capitalizedFirst
    }
}

// MARK: - Wear log (powers "one year ago today", stats, reuse boosts)
@Model
class WearLog {
    var date: Date
    var itemIDs: [UUID]
    var trendID: String?

    init(date: Date = Date(), itemIDs: [UUID], trendID: String? = nil) {
        self.date = date
        self.itemIDs = itemIDs
        self.trendID = trendID
    }
}

// MARK: - Outfits the user saved and named
@Model
class SavedOutfit {
    var id: UUID
    var name: String
    var itemIDs: [UUID]
    var dateCreated: Date
    var wearCount: Int = 0
    var lastWorn: Date? = nil

    init(name: String, itemIDs: [UUID]) {
        self.id = UUID()
        self.name = name
        self.itemIDs = itemIDs
        self.dateCreated = Date()
    }
}

// MARK: - Garment roles used by the outfit engine
nonisolated enum GarmentRole: String, CaseIterable, Codable, Identifiable {
    case top, bottom, outerwear, dress, shoes, accessory

    var id: String { rawValue }

    /// Maps a DeepFashion2 detector class name to a role
    init(detectorLabel: String) {
        switch detectorLabel {
        case "short_sleeve_top", "long_sleeve_top", "vest", "sling", "top":
            self = .top
        case "short_sleeve_outwear", "long_sleeve_outwear", "outerwear":
            self = .outerwear
        case "shorts", "trousers", "skirt", "bottom":
            self = .bottom
        case "short_sleeve_dress", "long_sleeve_dress", "vest_dress", "sling_dress", "dress":
            self = .dress
        case "shoes":
            self = .shoes
        case "accessory":
            self = .accessory
        default:
            self = .top
        }
    }

    var displayName: String {
        switch self {
        case .top: "Tops"
        case .bottom: "Bottoms"
        case .outerwear: "Outerwear"
        case .dress: "Dresses"
        case .shoes: "Shoes"
        case .accessory: "Accessories"
        }
    }

    var singular: String {
        switch self {
        case .top: "top"
        case .bottom: "bottom"
        case .outerwear: "jacket"
        case .dress: "dress"
        case .shoes: "shoes"
        case .accessory: "accessory"
        }
    }

    /// SF Symbol for the role ("jacket" / "figure.stand.dress" only exist on iOS 18+)
    var symbol: String {
        switch self {
        case .top: return "tshirt"
        case .bottom: return "figure.walk"
        case .outerwear:
            if #available(iOS 18.0, *) { return "jacket" }
            return "snowflake"
        case .dress:
            if #available(iOS 18.0, *) { return "figure.stand.dress" }
            return "figure.dress.line.vertical.figure"
        case .shoes: return "shoe"
        case .accessory: return "bag"
        }
    }

    /// Polyvore semantic category the OutfitScorer was trained on
    var polyvoreCategory: String {
        switch self {
        case .top: "tops"
        case .bottom: "bottoms"
        case .outerwear: "outerwear"
        case .dress: "all-body"
        case .shoes: "shoes"
        case .accessory: "accessories"
        }
    }
}

// MARK: - Shared attribute vocabulary
nonisolated enum Vocabulary {
    /// Same 12 colors (and order) as train_scorer.py COLORS
    static let colorHexes: [(name: String, hex: String)] = [
        ("black",  "#1E1E1E"),
        ("white",  "#F5F5F0"),
        ("red",    "#C0392B"),
        ("blue",   "#2E6FD8"),
        ("green",  "#3F8A4F"),
        ("yellow", "#E8C547"),
        ("pink",   "#E89AB5"),
        ("grey",   "#8E8E8E"),
        ("brown",  "#7B5236"),
        ("orange", "#E07B39"),
        ("purple", "#7D4E9E"),
        ("navy",   "#1F2F55"),
    ]
    static var colors: [String] { colorHexes.map(\.name) }

    static let patterns = ["solid", "striped", "floral", "graphic", "plaid",
                           "checkered", "print", "embroidered", "pleated", "unknown"]

    static let fabrics = ["cotton", "denim", "knit", "leather", "chiffon", "silk",
                          "wool", "lace", "velvet", "satin", "unknown"]

    static func hex(for color: String) -> String {
        colorHexes.first { $0.name == color }?.hex ?? "#8E8E8E"
    }
}

nonisolated extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
