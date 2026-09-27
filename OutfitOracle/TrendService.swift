//
//  TrendService.swift
//  OutfitOracle
//
//  Curated trend looks. A copy ships inside the app (Trends.json) so everything
//  works offline; the app also checks trends/trends.json in the GitHub repo so
//  the team can publish new seasonal trends without an App Store update.
//

import Foundation
import Observation

// MARK: - Models
nonisolated struct TrendFeed: Codable, Sendable {
    let version: Int
    let season: String
    let featuredID: String?
    let looks: [TrendLook]
}

nonisolated struct TrendLook: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let season: String
    let blurb: String
    let palette: [String]          // hex colors
    let slots: [TrendSlot]
}

nonisolated struct TrendSlot: Codable, Hashable, Sendable, Identifiable {
    let role: GarmentRole
    let colors: [String]
    let patterns: [String]
    let fabrics: [String]
    let searchTerm: String

    var id: String { role.rawValue + searchTerm }
}

/// Result of comparing a trend look against the user's closet
nonisolated struct TrendCoverage: Sendable {
    let look: TrendLook
    let matches: [(slot: TrendSlot, item: ItemSnapshot)]
    let missing: [TrendSlot]

    var fraction: Double {
        look.slots.isEmpty ? 0 : Double(matches.count) / Double(look.slots.count)
    }
    var summary: String {
        "You own \(matches.count) of \(look.slots.count) pieces"
    }
}

// MARK: - Matching
nonisolated enum TrendMatcher {
    /// Minimum similarity for an owned item to count as "you already have this"
    static let threshold = 0.5

    /// 0…1 similarity between an item and a trend slot (role must match)
    static func similarity(_ item: ItemSnapshot, _ slot: TrendSlot) -> Double {
        guard item.role == slot.role else { return 0 }
        var score = 0.4                                          // right kind of garment
        if slot.colors.isEmpty || slot.colors.contains(item.color) { score += 0.35 }
        if slot.patterns.isEmpty || slot.patterns.contains(item.pattern) { score += 0.15 }
        if slot.fabrics.isEmpty || slot.fabrics.contains(item.fabric) { score += 0.10 }
        return score
    }

    /// Greedy best-match of closet items to each slot (an item fills at most one slot)
    static func coverage(of look: TrendLook, closet: [ItemSnapshot]) -> TrendCoverage {
        var used = Set<UUID>()
        var matches: [(slot: TrendSlot, item: ItemSnapshot)] = []
        var missing: [TrendSlot] = []

        for slot in look.slots {
            let best = closet
                .filter { !used.contains($0.id) }
                .map { ($0, similarity($0, slot)) }
                .max { $0.1 < $1.1 }
            if let (item, sim) = best, sim >= threshold {
                used.insert(item.id)
                matches.append((slot: slot, item: item))
            } else {
                missing.append(slot)
            }
        }
        return TrendCoverage(look: look, matches: matches, missing: missing)
    }

    /// How well an outfit expresses a trend (used as a boost by OutfitEngine)
    static func match(outfit: [ItemSnapshot], to look: TrendLook) -> Double {
        guard !look.slots.isEmpty else { return 0 }
        let total = look.slots.reduce(0.0) { sum, slot in
            sum + (outfit.map { similarity($0, slot) }.max() ?? 0)
        }
        return total / Double(look.slots.count)
    }
}

// MARK: - Service
@Observable
final class TrendService {
    static let shared = TrendService()

    /// Raw JSON in the repo — edit + push trends/trends.json to update every install
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/theguru789/OutfitOracle/main/trends/trends.json")!

    private(set) var feed: TrendFeed
    private(set) var lastUpdated: Date?

    var looks: [TrendLook] { feed.looks }
    var featured: TrendLook? {
        feed.looks.first { $0.id == feed.featuredID } ?? feed.looks.first
    }

    private init() {
        let bundled = Self.loadBundled()
        let cached = Self.loadCached()
        // Use whichever copy is newer
        if let cached, cached.version > bundled.version {
            feed = cached
        } else {
            feed = bundled
        }
    }

    func look(id: String?) -> TrendLook? {
        guard let id else { return nil }
        return looks.first { $0.id == id }
    }

    /// Checks GitHub for a newer trend feed. Fails silently when offline.
    func refresh() async {
        guard UserDefaults.standard.object(forKey: "checkForTrends") as? Bool ?? true else { return }
        do {
            var request = URLRequest(url: Self.remoteURL)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 8
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            let remote = try JSONDecoder().decode(TrendFeed.self, from: data)
            if remote.version > feed.version {
                feed = remote
                try? data.write(to: Self.cacheURL, options: .atomic)
            }
            lastUpdated = Date()
        } catch {
            // Offline or bad JSON — keep the bundled / cached trends
        }
    }

    // MARK: Loading
    private static var cacheURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("trends.json")
    }

    private static func loadCached() -> TrendFeed? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(TrendFeed.self, from: data)
    }

    static func loadBundled() -> TrendFeed {
        guard let url = Bundle.main.url(forResource: "Trends", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let feed = try? JSONDecoder().decode(TrendFeed.self, from: data) else {
            return TrendFeed(version: 0, season: "", featuredID: nil, looks: [])
        }
        return feed
    }
}
