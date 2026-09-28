//
//  OutfitEngine.swift
//  OutfitOracle
//
//  Builds outfits from clothes the user already owns and ranks them with the
//  on-device OutfitScorer model (trained on Polyvore, see train_scorer.py),
//  plus small sustainability boosts: re-wear forgotten items, avoid repeats.
//

import CoreML
import Foundation

// MARK: - Value snapshot of a WardrobeItem (safe to use off the main thread)
nonisolated struct ItemSnapshot: Identifiable, Hashable, Sendable {
    let id: UUID
    let role: GarmentRole
    let color: String
    let pattern: String
    let fabric: String
    let daysSinceWorn: Int
    let name: String

    var isForgotten: Bool { daysSinceWorn >= 30 }
}

extension WardrobeItem {
    var snapshot: ItemSnapshot {
        ItemSnapshot(id: id, role: role, color: color, pattern: pattern,
                     fabric: fabricType, daysSinceWorn: daysSinceWorn, name: name)
    }
}

nonisolated struct WeatherSnapshot: Sendable, Equatable {
    let highC: Double
    let lowC: Double
    let symbol: String

    var isCold: Bool { highC < 12 }
    var isHot: Bool { highC > 26 }
}

nonisolated struct Outfit: Identifiable, Sendable {
    let id = UUID()
    let items: [ItemSnapshot]
    let modelScore: Double     // 0…1 from OutfitScorer
    let score: Double          // final score incl. boosts
    let reasons: [String]

    var itemIDs: [UUID] { items.map(\.id) }
    var percent: Int { Int((min(max(modelScore, 0), 1) * 100).rounded()) }
}

// MARK: - Encoder that mirrors train_scorer.py exactly
nonisolated enum ScorerEncoder {
    // Same lists, same order as train_scorer.py
    static let categories = ["accessories", "all-body", "bags", "bottoms", "hats",
                             "jewellery", "outerwear", "scarves", "shoes", "sunglasses", "tops"]
    static let colors     = ["black", "white", "red", "blue", "green", "yellow",
                             "pink", "grey", "brown", "orange", "purple", "navy"]
    static let patterns   = ["floral", "striped", "solid", "print", "graphic",
                             "plaid", "checkered", "abstract", "geometric"]
    static let fabrics    = ["chiffon", "denim", "leather", "knit", "cotton",
                             "silk", "lace", "velvet", "wool", "satin"]

    static let maxItems = 4
    static let itemDim  = categories.count + colors.count + patterns.count + fabrics.count  // 42
    static let inputDim = itemDim * maxItems                                                 // 168

    static func encode(_ item: ItemSnapshot) -> [Float] {
        var vec = [Float](repeating: 0, count: itemDim)
        if let i = categories.firstIndex(of: item.role.polyvoreCategory) {
            vec[i] = 1
        }
        var offset = categories.count
        if let i = colors.firstIndex(of: item.color) {
            vec[offset + i] = 1
        }
        offset += colors.count
        if let i = patterns.firstIndex(of: item.pattern) {   // embroidered / pleated have no slot
            vec[offset + i] = 1
        }
        offset += patterns.count
        if let i = fabrics.firstIndex(of: item.fabric) {
            vec[offset + i] = 1
        }
        return vec
    }

    /// Concatenates up to 4 item vectors, zero-padded to 168
    static func encode(outfit items: [ItemSnapshot]) -> [Float] {
        var vec: [Float] = []
        vec.reserveCapacity(inputDim)
        for item in items.prefix(maxItems) {
            vec += encode(item)
        }
        vec += [Float](repeating: 0, count: inputDim - vec.count)
        return vec
    }

    /// Polyvore outfits usually list the main piece first, then layers, bottoms, shoes, extras
    static func polyvoreOrder(_ role: GarmentRole) -> Int {
        switch role {
        case .top: 0
        case .dress: 1
        case .outerwear: 2
        case .bottom: 3
        case .shoes: 4
        case .accessory: 5
        }
    }
}

// MARK: - Engine
nonisolated final class OutfitEngine: @unchecked Sendable {
    static let shared = OutfitEngine()

    private let scorer: MLModel?
    private let inputShape: [NSNumber]

    static let maxCandidates = 2500

    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        if let url = Bundle.main.url(forResource: "OutfitScorer", withExtension: "mlmodelc"),
           let model = try? MLModel(contentsOf: url, configuration: config) {
            scorer = model
            inputShape = model.modelDescription.inputDescriptionsByName["outfitVector"]?
                .multiArrayConstraint?.shape ?? [1, NSNumber(value: ScorerEncoder.inputDim)]
        } else {
            scorer = nil
            inputShape = [1, NSNumber(value: ScorerEncoder.inputDim)]
        }
    }

    var usesModel: Bool { scorer != nil }

    // MARK: Public API
    @concurrent
    func suggestOutfits(
        from items: [ItemSnapshot],
        trend: TrendLook? = nil,
        weather: WeatherSnapshot? = nil,
        favoriteColors: Set<String> = [],
        recentlyWorn: [Set<UUID>] = [],
        count: Int = 5
    ) async -> [Outfit] {
        let candidates = Self.candidateSets(from: items)
        let scored = candidates.map { set in
            score(set, trend: trend, weather: weather,
                  favoriteColors: favoriteColors, recentlyWorn: recentlyWorn)
        }
        return Self.diversePick(scored.sorted { $0.score > $1.score }, count: count)
    }

    // MARK: Candidate generation
    /// (top + bottom) or (dress), optionally + outerwear, + shoes, + accessory — max 4 items
    static func candidateSets(from items: [ItemSnapshot]) -> [[ItemSnapshot]] {
        let by = Dictionary(grouping: items, by: \.role)
        let tops = by[.top] ?? [], bottoms = by[.bottom] ?? [], dresses = by[.dress] ?? []
        let outer: [ItemSnapshot?] = [nil] + (by[.outerwear] ?? []).map { $0 }
        let shoes: [ItemSnapshot?] = [nil] + (by[.shoes] ?? []).map { $0 }
        let extras: [ItemSnapshot?] = [nil] + (by[.accessory] ?? []).map { $0 }

        var bases: [[ItemSnapshot]] = dresses.map { [$0] }
        for t in tops { for b in bottoms { bases.append([t, b]) } }

        var sets: [[ItemSnapshot]] = []
        for base in bases {
            for o in outer {
                for s in shoes {
                    for e in extras {
                        let set = base + [o, s, e].compactMap { $0 }
                        if set.count <= ScorerEncoder.maxItems { sets.append(set) }
                    }
                }
            }
        }
        if sets.count > maxCandidates {
            sets = Array(sets.shuffled().prefix(maxCandidates))
        }
        return sets.map { $0.sorted { ScorerEncoder.polyvoreOrder($0.role) < ScorerEncoder.polyvoreOrder($1.role) } }
    }

    // MARK: Scoring
    func modelScore(_ set: [ItemSnapshot]) -> Double {
        guard let scorer,
              let array = try? MLMultiArray(shape: inputShape, dataType: .float32) else {
            return Self.ruleScore(set)
        }
        let vec = ScorerEncoder.encode(outfit: set)
        for (i, v) in vec.enumerated() where i < array.count {
            array[i] = NSNumber(value: v)
        }
        guard let input = try? MLDictionaryFeatureProvider(dictionary: ["outfitVector": array]),
              let output = try? scorer.prediction(from: input),
              let result = output.featureValue(for: "compatibilityScore") else {
            return Self.ruleScore(set)
        }
        if let arr = result.multiArrayValue, arr.count > 0 {
            return arr[0].doubleValue
        }
        return result.doubleValue
    }

    func score(
        _ set: [ItemSnapshot],
        trend: TrendLook?,
        weather: WeatherSnapshot?,
        favoriteColors: Set<String>,
        recentlyWorn: [Set<UUID>]
    ) -> Outfit {
        let base = modelScore(set)
        var total = base
        var reasons: [String] = []

        // Re-wear & remix: nudge forgotten pieces back into rotation
        let forgotten = set.filter(\.isForgotten)
        if !forgotten.isEmpty {
            total += 0.08 * Double(forgotten.count) / Double(set.count)
            if let first = forgotten.first {
                reasons.append("Brings back your \(first.name.lowercased()) (not worn in \(first.daysSinceWorn) days)")
            }
        }

        // Trend match
        if let trend {
            let match = TrendMatcher.match(outfit: set, to: trend)
            total += 0.2 * match
            if match > 0.4 { reasons.append("Fits the \(trend.name) trend") }
        }

        // Weather
        if let weather {
            let hasLayer = set.contains { $0.role == .outerwear }
            if weather.isCold && hasLayer {
                total += 0.1
                reasons.append("Layered for \(WeatherService.format(weather.highC)) weather")
            } else if weather.isCold && !hasLayer {
                total -= 0.05
            } else if weather.isHot && hasLayer {
                total -= 0.12
            }
        }

        // Personal color preferences
        let favoriteHits = set.filter { favoriteColors.contains($0.color) }.count
        total += 0.03 * Double(favoriteHits)

        // Don't repeat the exact same look within a week
        let ids = Set(set.map(\.id))
        if recentlyWorn.contains(ids) {
            total -= 0.25
            reasons.append("Worn recently")
        }

        reasons.insert("\(Int((min(max(base, 0), 1) * 100).rounded()))% style match", at: 0)
        return Outfit(items: set, modelScore: base, score: total, reasons: reasons)
    }

    /// Fallback when the Core ML model isn't available: simple color / pattern harmony
    static func ruleScore(_ set: [ItemSnapshot]) -> Double {
        let neutrals: Set<String> = ["black", "white", "grey", "navy", "brown"]
        let accents = Set(set.map(\.color)).subtracting(neutrals).subtracting(["unknown"])
        let loudPatterns = set.filter { !["solid", "unknown"].contains($0.pattern) }.count
        var score = 0.75
        score -= Double(max(0, accents.count - 1)) * 0.15   // >1 accent color clashes
        score -= Double(max(0, loudPatterns - 1)) * 0.15    // >1 bold pattern clashes
        return min(max(score, 0.05), 0.95)
    }

    /// Top N, but no single item appears in more than 2 of them
    static func diversePick(_ sorted: [Outfit], count: Int) -> [Outfit] {
        var picked: [Outfit] = []
        var uses: [UUID: Int] = [:]
        for outfit in sorted where picked.count < count {
            if outfit.items.contains(where: { uses[$0.id, default: 0] >= 2 }) { continue }
            picked.append(outfit)
            outfit.items.forEach { uses[$0.id, default: 0] += 1 }
        }
        // Small closets: relax the rule rather than return nothing
        if picked.isEmpty { return Array(sorted.prefix(count)) }
        return picked
    }
}
