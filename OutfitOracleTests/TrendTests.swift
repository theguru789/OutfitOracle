//
//  TrendTests.swift
//  OutfitOracleTests
//
//  Trend feed integrity + closet coverage matching.
//

import Foundation
import Testing
@testable import OutfitOracle

struct TrendFeedTests {

    private func bundledFeed() throws -> TrendFeed {
        let url = try #require(Bundle.main.url(forResource: "Trends", withExtension: "json"))
        return try JSONDecoder().decode(TrendFeed.self, from: Data(contentsOf: url))
    }

    @Test func bundledTrendsDecode() throws {
        let feed = try bundledFeed()
        #expect(feed.version >= 1)
        #expect(!feed.looks.isEmpty)
        #expect(feed.looks.allSatisfy { !$0.slots.isEmpty && !$0.palette.isEmpty })
    }

    @Test func idsAreUniqueAndFeaturedExists() throws {
        let feed = try bundledFeed()
        #expect(Set(feed.looks.map(\.id)).count == feed.looks.count)
        let featured = try #require(feed.featuredID)
        #expect(feed.looks.contains { $0.id == featured })
    }

    @Test func slotAttributesUseTheAppVocabulary() throws {
        let slots = try bundledFeed().looks.flatMap(\.slots)
        #expect(slots.flatMap(\.colors).allSatisfy { Vocabulary.colors.contains($0) })
        #expect(slots.flatMap(\.patterns).allSatisfy { Vocabulary.patterns.contains($0) })
        #expect(slots.flatMap(\.fabrics).allSatisfy { Vocabulary.fabrics.contains($0) })
        #expect(slots.allSatisfy { !$0.searchTerm.isEmpty })
    }

    @Test func paletteColorsAreValidHex() throws {
        let hexes = try bundledFeed().looks.flatMap(\.palette)
        #expect(hexes.allSatisfy { $0.count == 7 && $0.hasPrefix("#") && UInt64($0.dropFirst(), radix: 16) != nil })
    }

    /// trends/trends.json (what the app downloads) should match the bundled copy
    /// until someone deliberately publishes a newer version.
    @Test func remoteCopyIsValidAndNotOlder() throws {
        let repoCopy = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("trends/trends.json")
        let remote = try JSONDecoder().decode(TrendFeed.self, from: Data(contentsOf: repoCopy))
        let bundled = try bundledFeed()
        #expect(remote.version >= bundled.version)
        #expect(remote.looks.count >= 1)
    }
}

struct TrendMatcherTests {

    @Test func coverageCountsOwnedPieces() {
        let closet = [snap(.top, "white", fabric: "cotton"), snap(.bottom, "blue", fabric: "denim")]
        let coverage = TrendMatcher.coverage(of: denimLook, closet: closet)
        #expect(coverage.matches.count == 2)
        #expect(coverage.missing.map(\.searchTerm) == ["denim jacket"])
        #expect(abs(coverage.fraction - 2.0 / 3.0) < 0.001)
        #expect(coverage.summary == "You own 2 of 3 pieces")
    }

    @Test func wrongRoleNeverMatches() {
        let closet = [snap(.shoes, "blue", fabric: "denim")]
        #expect(TrendMatcher.coverage(of: denimLook, closet: closet).matches.isEmpty)
    }

    @Test func wrongColorAloneIsNotEnough() {
        // Right garment type but the wrong color, pattern and fabric
        let closet = [snap(.bottom, "red", pattern: "floral", fabric: "chiffon")]
        #expect(TrendMatcher.coverage(of: denimLook, closet: closet).matches.isEmpty)
    }

    @Test func oneItemFillsAtMostOneSlot() {
        let look = TrendLook(id: "two-tops", name: "Two tops", season: "", blurb: "", palette: [], slots: [
            TrendSlot(role: .top, colors: [], patterns: [], fabrics: [], searchTerm: "a"),
            TrendSlot(role: .top, colors: [], patterns: [], fabrics: [], searchTerm: "b"),
        ])
        let coverage = TrendMatcher.coverage(of: look, closet: [snap(.top)])
        #expect(coverage.matches.count == 1 && coverage.missing.count == 1)
    }

    @Test func fullClosetNeedsNoShopping() {
        let closet = [snap(.top, "white", fabric: "cotton"), snap(.bottom, "blue", fabric: "denim"),
                      snap(.outerwear, "blue", fabric: "denim")]
        let coverage = TrendMatcher.coverage(of: denimLook, closet: closet)
        #expect(coverage.missing.isEmpty && coverage.fraction == 1)
    }

    @Test func matchScoreRanksOnTrendOutfitsHigher() {
        let onTrend = [snap(.top, "white", fabric: "cotton"), snap(.bottom, "blue", fabric: "denim")]
        let offTrend = [snap(.top, "red", fabric: "knit"), snap(.bottom, "black", fabric: "wool")]
        #expect(TrendMatcher.match(outfit: onTrend, to: denimLook) > TrendMatcher.match(outfit: offTrend, to: denimLook))
    }
}
