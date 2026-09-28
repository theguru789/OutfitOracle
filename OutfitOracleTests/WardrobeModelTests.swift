//
//  WardrobeModelTests.swift
//  OutfitOracleTests
//
//  GarmentRole mapping, shared vocabulary and WardrobeItem helpers.
//

import Foundation
import SwiftData
import Testing
@testable import OutfitOracle

struct GarmentRoleTests {

    @Test func everyDetectorClassMapsToARole() {
        // All 13 DeepFashion2 classes baked into GarmentDetector
        let expected: [String: GarmentRole] = [
            "short_sleeve_top": .top, "long_sleeve_top": .top, "vest": .top, "sling": .top,
            "short_sleeve_outwear": .outerwear, "long_sleeve_outwear": .outerwear,
            "shorts": .bottom, "trousers": .bottom, "skirt": .bottom,
            "short_sleeve_dress": .dress, "long_sleeve_dress": .dress,
            "vest_dress": .dress, "sling_dress": .dress,
        ]
        #expect(expected.count == 13)
        for (label, role) in expected {
            #expect(GarmentRole(detectorLabel: label) == role, "\(label)")
        }
    }

    @Test func unknownLabelsFallBackToTop() {
        #expect(GarmentRole(detectorLabel: "mystery") == .top)
    }

    @Test(arguments: GarmentRole.allCases)
    func everyRoleHasAnIcon(role: GarmentRole) {
        #expect(!role.symbol.isEmpty)
        #expect(!role.displayName.isEmpty)
    }
}

struct VocabularyTests {

    @Test func colorsMatchTheScorer() {
        #expect(Vocabulary.colors == ScorerEncoder.colors)
    }

    @Test func everyColorHasAHexSwatch() {
        for color in Vocabulary.colors {
            #expect(Vocabulary.hex(for: color).hasPrefix("#"))
            #expect(Vocabulary.hex(for: color).count == 7)
        }
    }
}

@MainActor
struct WardrobeItemTests {

    /// @Model objects need a live container, even when they're never saved
    private let container: ModelContainer

    init() throws {
        container = try makeInMemoryContainer()
    }

    @Test func defaultNameIsBuiltFromAttributes() {
        #expect(WardrobeItem.defaultName(color: "green", fabric: "knit", role: .top) == "Green knit top")
        #expect(WardrobeItem.defaultName(color: "unknown", fabric: "unknown", role: .dress) == "Dress")
    }

    @Test func newItemsPickUpRoleAndSwatchFromDetectorLabel() {
        let item = WardrobeItem(croppedImageData: Data(), category: "trousers", color: "brown")
        #expect(item.role == .bottom)
        #expect(item.colorHex == Vocabulary.hex(for: "brown"))
        #expect(item.wearCount == 0)
        #expect(!item.isArchived)
    }

    @Test func markWornUpdatesCountAndDate() {
        let item = WardrobeItem(croppedImageData: Data(), category: "top")
        item.markWorn()
        item.markWorn()
        #expect(item.wearCount == 2)
        #expect(item.lastWorn != nil)
        #expect(item.daysSinceWorn == 0)
    }

    @Test func itemsUnwornFor30DaysAreForgotten() {
        let item = WardrobeItem(croppedImageData: Data(), category: "top")
        item.lastWorn = Calendar.current.date(byAdding: .day, value: -31, to: Date())
        #expect(item.isForgotten)
        item.markWorn()
        #expect(!item.isForgotten)
    }

    @Test func snapshotCopiesAttributes() {
        let item = WardrobeItem(croppedImageData: Data(), category: "long_sleeve_top",
                                color: "green", pattern: "solid", fabricType: "knit")
        let s = item.snapshot
        #expect(s.id == item.id && s.role == .top && s.color == "green" && s.fabric == "knit")
    }
}
