//
//  SampleData.swift
//  OutfitOracle
//
//  A ready-made closet for demos and the Simulator, so outfits, trends and
//  chat can be tried without photographing real clothes.
//

import SwiftData
import UIKit

enum SampleData {
    private struct Sample {
        let name: String
        let role: GarmentRole
        let color: String
        let pattern: String
        let fabric: String
        let daysSinceWorn: Int?   // nil = never worn
        let wearCount: Int
    }

    private static let samples: [Sample] = [
        Sample(name: "Cream knit sweater", role: .top, color: "white", pattern: "solid", fabric: "knit", daysSinceWorn: 3, wearCount: 12),
        Sample(name: "Navy striped shirt", role: .top, color: "navy", pattern: "striped", fabric: "cotton", daysSinceWorn: 45, wearCount: 4),
        Sample(name: "White cotton tee", role: .top, color: "white", pattern: "solid", fabric: "cotton", daysSinceWorn: 1, wearCount: 20),
        Sample(name: "Grey chunky knit", role: .top, color: "grey", pattern: "solid", fabric: "knit", daysSinceWorn: 60, wearCount: 2),
        Sample(name: "Red knit sweater", role: .top, color: "red", pattern: "solid", fabric: "knit", daysSinceWorn: nil, wearCount: 0),
        Sample(name: "Straight leg jeans", role: .bottom, color: "blue", pattern: "solid", fabric: "denim", daysSinceWorn: 2, wearCount: 25),
        Sample(name: "Black trousers", role: .bottom, color: "black", pattern: "solid", fabric: "cotton", daysSinceWorn: 10, wearCount: 8),
        Sample(name: "Brown wide-leg pants", role: .bottom, color: "brown", pattern: "solid", fabric: "wool", daysSinceWorn: 35, wearCount: 3),
        Sample(name: "Floral midi dress", role: .dress, color: "pink", pattern: "floral", fabric: "chiffon", daysSinceWorn: 90, wearCount: 2),
        Sample(name: "Denim jacket", role: .outerwear, color: "blue", pattern: "solid", fabric: "denim", daysSinceWorn: 7, wearCount: 9),
        Sample(name: "Black leather jacket", role: .outerwear, color: "black", pattern: "solid", fabric: "leather", daysSinceWorn: 40, wearCount: 5),
        Sample(name: "White sneakers", role: .shoes, color: "white", pattern: "solid", fabric: "leather", daysSinceWorn: 1, wearCount: 30),
        Sample(name: "Brown leather boots", role: .shoes, color: "brown", pattern: "solid", fabric: "leather", daysSinceWorn: 14, wearCount: 10),
        Sample(name: "Grey knit scarf", role: .accessory, color: "grey", pattern: "solid", fabric: "knit", daysSinceWorn: nil, wearCount: 0),
    ]

    @MainActor
    static func load(into context: ModelContext) {
        let calendar = Calendar.current
        var created: [WardrobeItem] = []

        for sample in samples {
            let hex = Vocabulary.hex(for: sample.color)
            let item = WardrobeItem(
                croppedImageData: placeholderImage(symbol: sample.role.symbol, hex: hex),
                category: sample.role.rawValue,
                role: sample.role,
                color: sample.color,
                colorHex: hex,
                pattern: sample.pattern,
                styleTag: "casual",
                fabricType: sample.fabric,
                name: sample.name
            )
            item.dateAdded = calendar.date(byAdding: .day, value: -120, to: Date()) ?? Date()
            item.wearCount = sample.wearCount
            item.lastWorn = sample.daysSinceWorn.flatMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
            context.insert(item)
            created.append(item)
        }

        // A memory for the "One year ago today" card
        if let yearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) {
            let ids = created.filter { ["Floral midi dress", "Brown leather boots"].contains($0.name) }.map(\.id)
            context.insert(WearLog(date: yearAgo, itemIDs: ids))
        }
        // A couple of recent outfits for weekly stats
        for (daysAgo, names) in [(1, ["White cotton tee", "Straight leg jeans", "White sneakers"]),
                                 (3, ["Cream knit sweater", "Black trousers", "Brown leather boots"])] {
            let ids = created.filter { names.contains($0.name) }.map(\.id)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            context.insert(WearLog(date: date, itemIDs: ids))
        }
        try? context.save()
    }

    /// Soft colored card with the garment's SF Symbol — stands in for a photo
    static func placeholderImage(symbol: String, hex: String) -> Data {
        let size = CGSize(width: 300, height: 360)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            // Light garments get a darker card so they stay visible
            let isLight = ["#F5F5F0", "#E8C547"].contains(hex)
            (isLight ? UIColor(red: 0.62, green: 0.55, blue: 0.47, alpha: 1)
                     : UIColor(red: 0.94, green: 0.92, blue: 0.87, alpha: 1)).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let config = UIImage.SymbolConfiguration(pointSize: 170, weight: .regular)
            let tint = UIColor(hex: hex)
            if let glyph = UIImage(systemName: symbol, withConfiguration: config)?
                .withTintColor(tint, renderingMode: .alwaysOriginal) {
                let rect = CGRect(x: (size.width - glyph.size.width) / 2,
                                  y: (size.height - glyph.size.height) / 2,
                                  width: glyph.size.width, height: glyph.size.height)
                glyph.draw(in: rect)
            }
        }
        return image.jpegData(compressionQuality: 0.85) ?? Data()
    }
}

extension UIColor {
    convenience init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))).scanHexInt64(&value)
        self.init(red: CGFloat((value >> 16) & 0xFF) / 255,
                  green: CGFloat((value >> 8) & 0xFF) / 255,
                  blue: CGFloat(value & 0xFF) / 255,
                  alpha: 1)
    }
}
