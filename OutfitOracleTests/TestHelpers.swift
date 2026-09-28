//
//  TestHelpers.swift
//  OutfitOracleTests
//
//  Shared fixtures for the unit tests.
//

import Foundation
import SwiftData
import UIKit
@testable import OutfitOracle

/// Quick value snapshot of a garment for engine / matcher tests
func snap(_ role: GarmentRole, _ color: String = "black", pattern: String = "solid",
          fabric: String = "cotton", days: Int = 0, name: String = "item") -> ItemSnapshot {
    ItemSnapshot(id: UUID(), role: role, color: color, pattern: pattern,
                 fabric: fabric, daysSinceWorn: days, name: name)
}

/// 64×64 image filled with one color (for ColorExtractor tests)
func solidImage(_ color: UIColor) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64), format: format).image { ctx in
        color.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
    }
}

/// A small 3-piece trend look used across tests
let denimLook = TrendLook(
    id: "test-denim", name: "Denim on Denim", season: "Test", blurb: "",
    palette: ["#1F2F55"],
    slots: [
        TrendSlot(role: .top, colors: ["white"], patterns: ["solid"], fabrics: ["cotton"], searchTerm: "white tee"),
        TrendSlot(role: .bottom, colors: ["blue"], patterns: [], fabrics: ["denim"], searchTerm: "jeans"),
        TrendSlot(role: .outerwear, colors: ["blue"], patterns: [], fabrics: ["denim"], searchTerm: "denim jacket"),
    ]
)

/// Fresh in-memory SwiftData store (never touches the real closet)
@MainActor
func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([WardrobeItem.self, WearLog.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}
