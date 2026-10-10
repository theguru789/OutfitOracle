//
//  Preferences.swift
//  OutfitOracle
//
//  What the user told us about themselves in the intro / Settings:
//  male / female (for shop links) and their style in their own words.
//

import Foundation

nonisolated enum Gender: String, CaseIterable, Identifiable, Sendable {
    case male, female, unspecified

    var id: String { rawValue }

    var label: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .unspecified: "Prefer not to say"
        }
    }

    /// Word added to store searches ("men's denim jacket")
    var shopPrefix: String? {
        switch self {
        case .male: "men's"
        case .female: "women's"
        case .unspecified: nil
        }
    }

    static var current: Gender {
        Gender(rawValue: UserDefaults.standard.string(forKey: PrefKeys.gender) ?? "") ?? .unspecified
    }
}

/// Likes and dislikes pulled from favorite colors + the free-text style note,
/// e.g. "comfy, earthy colors, no skirts, hate leather" → avoid leather.
nonisolated struct StylePreferences: Sendable, Equatable {
    var likedColors: Set<String> = []
    var dislikedColors: Set<String> = []
    var likedPatterns: Set<String> = []
    var dislikedPatterns: Set<String> = []
    var likedFabrics: Set<String> = []
    var dislikedFabrics: Set<String> = []
    var dislikedRoles: Set<GarmentRole> = []
    var notes: String = ""

    static let none = StylePreferences()

    static var current: StylePreferences {
        let defaults = UserDefaults.standard
        var prefs = parse(defaults.string(forKey: PrefKeys.styleNotes) ?? "")
        prefs.likedColors.formUnion(defaults.favoriteColors)
        return prefs
    }

    /// Words that flip what follows them (until the next comma/period) into a dislike
    private static let negations = ["no ", "not ", "don't like ", "dont like ", "do not like ", "hate ",
                                    "avoid ", "without ", "never ", "dislike ", "nothing "]

    private static let roleWords: [String: GarmentRole] = [
        "dress": .dress, "dresses": .dress,
        "jacket": .outerwear, "jackets": .outerwear, "coat": .outerwear, "coats": .outerwear, "layers": .outerwear,
        "accessories": .accessory, "accessory": .accessory,
    ]

    /// Extra color words people use → the app's 12 colors
    private static let colorSynonyms: [String: String] = [
        "gray": "grey", "beige": "brown", "tan": "brown", "camel": "brown", "olive": "green",
        "cream": "white", "ivory": "white", "burgundy": "red", "maroon": "red", "neon": "yellow",
    ]

    static func parse(_ text: String) -> StylePreferences {
        var prefs = StylePreferences(notes: text.trimmingCharacters(in: .whitespacesAndNewlines))
        let clauses = text.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .components(separatedBy: CharacterSet(charactersIn: ",.;\n!"))

        for rawClause in clauses {
            var clause = " " + rawClause.trimmingCharacters(in: .whitespaces) + " "
            var negative = false
            for word in negations where clause.contains(" " + word) {
                negative = true
                clause = clause.replacingOccurrences(of: " " + word, with: " ")
            }
            let words = Set(clause.split(whereSeparator: { !$0.isLetter }).map(String.init))

            for word in words {
                let color = colorSynonyms[word] ?? word
                if Vocabulary.colors.contains(color) {
                    if negative { prefs.dislikedColors.insert(color) } else { prefs.likedColors.insert(color) }
                }
                let pattern = word == "stripes" ? "striped" : (word == "florals" ? "floral" : word)
                if Vocabulary.patterns.contains(pattern) && pattern != "unknown" {
                    if negative { prefs.dislikedPatterns.insert(pattern) } else { prefs.likedPatterns.insert(pattern) }
                }
                if Vocabulary.fabrics.contains(word) && word != "unknown" {
                    if negative { prefs.dislikedFabrics.insert(word) } else { prefs.likedFabrics.insert(word) }
                }
                if negative, let role = roleWords[word] {
                    prefs.dislikedRoles.insert(role)
                }
            }
        }
        // "earthy" / "neutral" are common ways to describe a palette
        if text.lowercased().contains("earthy") { prefs.likedColors.formUnion(["brown", "green"]) }
        if text.lowercased().contains("neutral") { prefs.likedColors.formUnion(["white", "grey", "black", "brown"]) }
        return prefs
    }

    /// Score adjustment for one outfit (small boost for likes, clear penalty for dislikes)
    func adjustment(for items: [ItemSnapshot]) -> Double {
        var total = 0.0
        for item in items {
            if dislikedColors.contains(item.color) || dislikedPatterns.contains(item.pattern)
                || dislikedFabrics.contains(item.fabric) || dislikedRoles.contains(item.role) {
                total -= 0.15
            }
            if likedColors.contains(item.color) { total += 0.03 }
            if likedPatterns.contains(item.pattern) { total += 0.02 }
            if likedFabrics.contains(item.fabric) { total += 0.02 }
        }
        return total
    }
}
