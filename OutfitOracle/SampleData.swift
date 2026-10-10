//
//  SampleData.swift
//  OutfitOracle
//
//  A ready-made men's closet of real clothing photos (backgrounds already
//  removed) so outfits, trends, chat and Closet ▸ Outfits can be tried right away.
//  Photos: Pexels (free license) + garments cut from the bundled outfit_sample.
//

import SwiftData
import UIKit

enum SampleData {

    private struct Sample {
        let name: String
        let asset: String           // "sample_<asset>" in Assets.xcassets/SampleCloset
        let role: GarmentRole
        let color: String
        let pattern: String
        let fabric: String
        let daysSinceWorn: Int?     // nil = never worn
        let wearCount: Int
    }

    private static let samples: [Sample] = [
        // Tops
        Sample(name: "White cotton tee", asset: "white_tee", role: .top, color: "white", pattern: "solid", fabric: "cotton", daysSinceWorn: 1, wearCount: 20),
        Sample(name: "Black tee", asset: "black_tee", role: .top, color: "black", pattern: "solid", fabric: "cotton", daysSinceWorn: 9, wearCount: 14),
        Sample(name: "Navy striped sweater", asset: "navy_striped_sweater", role: .top, color: "navy", pattern: "striped", fabric: "knit", daysSinceWorn: 45, wearCount: 4),
        Sample(name: "Red knit sweater", asset: "red_knit_sweater", role: .top, color: "red", pattern: "solid", fabric: "knit", daysSinceWorn: nil, wearCount: 0),
        Sample(name: "Blue sweatshirt", asset: "blue_sweatshirt", role: .top, color: "blue", pattern: "solid", fabric: "cotton", daysSinceWorn: 12, wearCount: 8),
        Sample(name: "Olive knit sweater", asset: "olive_sweater", role: .top, color: "green", pattern: "solid", fabric: "knit", daysSinceWorn: 50, wearCount: 6),
        Sample(name: "Sage button-down shirt", asset: "sage_shirt", role: .top, color: "green", pattern: "solid", fabric: "cotton", daysSinceWorn: 18, wearCount: 6),

        // Bottoms
        Sample(name: "Straight leg jeans", asset: "straight_jeans", role: .bottom, color: "blue", pattern: "solid", fabric: "denim", daysSinceWorn: 2, wearCount: 25),
        Sample(name: "Brown wide-leg pants", asset: "brown_pants", role: .bottom, color: "brown", pattern: "solid", fabric: "wool", daysSinceWorn: 35, wearCount: 3),
        Sample(name: "Dark wash jeans", asset: "dark_jeans", role: .bottom, color: "navy", pattern: "solid", fabric: "denim", daysSinceWorn: 5, wearCount: 16),


        // Outerwear
        Sample(name: "Denim jacket", asset: "denim_jacket", role: .outerwear, color: "blue", pattern: "solid", fabric: "denim", daysSinceWorn: 7, wearCount: 9),
        Sample(name: "Black puffer jacket", asset: "black_puffer", role: .outerwear, color: "black", pattern: "solid", fabric: "unknown", daysSinceWorn: 60, wearCount: 3),
        Sample(name: "Beige overshirt", asset: "beige_overshirt", role: .outerwear, color: "brown", pattern: "solid", fabric: "cotton", daysSinceWorn: 15, wearCount: 5),
        Sample(name: "Brown leather jacket", asset: "leather_jacket", role: .outerwear, color: "brown", pattern: "solid", fabric: "leather", daysSinceWorn: 4, wearCount: 15),
        Sample(name: "Grey wool overshirt", asset: "grey_overshirt", role: .outerwear, color: "grey", pattern: "solid", fabric: "wool", daysSinceWorn: 40, wearCount: 4),

        // Shoes
        Sample(name: "White sneakers", asset: "white_sneakers", role: .shoes, color: "white", pattern: "solid", fabric: "leather", daysSinceWorn: 1, wearCount: 30),
        Sample(name: "Black canvas sneakers", asset: "black_canvas_sneakers", role: .shoes, color: "black", pattern: "solid", fabric: "cotton", daysSinceWorn: 8, wearCount: 12),
        Sample(name: "Brown sneakers", asset: "brown_sneakers", role: .shoes, color: "brown", pattern: "striped", fabric: "leather", daysSinceWorn: 6, wearCount: 11),
        Sample(name: "Brown oxford shoes", asset: "brown_oxfords", role: .shoes, color: "brown", pattern: "solid", fabric: "leather", daysSinceWorn: 70, wearCount: 2),
        Sample(name: "Black lace-up boots", asset: "black_lace_up_boots", role: .shoes, color: "black", pattern: "solid", fabric: "leather", daysSinceWorn: 9, wearCount: 10),

        // Accessories
        Sample(name: "Black sunglasses", asset: "black_sunglasses", role: .accessory, color: "black", pattern: "solid", fabric: "unknown", daysSinceWorn: 3, wearCount: 20),
        Sample(name: "Brown leather belt", asset: "leather_belt", role: .accessory, color: "brown", pattern: "solid", fabric: "leather", daysSinceWorn: 20, wearCount: 7),
    ]

    static var allNames: Set<String> { Set(samples.map(\.name)) }

    @MainActor
    static func load(into context: ModelContext) {
        let calendar = Calendar.current
        var created: [WardrobeItem] = []

        // Loading twice (intro + Settings) shouldn't duplicate the closet
        let existingNames = Set(((try? context.fetch(FetchDescriptor<WardrobeItem>())) ?? []).map(\.name))

        for sample in samples where !existingNames.contains(sample.name) {
            let hex = Vocabulary.hex(for: sample.color)
            let photo = UIImage(named: "sample_\(sample.asset)")?.pngData()
            let item = WardrobeItem(
                croppedImageData: photo ?? placeholderImage(symbol: sample.role.symbol, hex: hex),
                category: sample.role.rawValue,
                role: sample.role,
                color: sample.color,
                colorHex: hex,
                pattern: sample.pattern,
                styleTag: "casual",
                fabricType: sample.fabric,
                name: sample.name
            )
            item.cutoutImageData = photo          // sample photos already have the background removed
            item.dateAdded = calendar.date(byAdding: .day, value: -120, to: Date()) ?? Date()
            item.wearCount = sample.wearCount
            item.lastWorn = sample.daysSinceWorn.flatMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
            context.insert(item)
            created.append(item)
        }

        guard !created.isEmpty else { return }   // sample closet was already loaded

        func ids(_ names: [String]) -> [UUID] {
            names.compactMap { name in created.first { $0.name == name }?.id }
        }
        // A memory for the "One year ago today" card
        if let yearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) {
            context.insert(WearLog(date: yearAgo, itemIDs: ids(["Olive knit sweater", "Brown wide-leg pants", "Brown leather jacket"])))
        }
        // A couple of recent outfits for weekly stats
        for (daysAgo, names) in [(1, ["White cotton tee", "Straight leg jeans", "White sneakers"]),
                                 (3, ["Navy striped sweater", "Brown wide-leg pants", "Brown sneakers"])] {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            context.insert(WearLog(date: date, itemIDs: ids(names)))
        }
        // Two named outfits so the Outfits tab has something to show
        context.insert(SavedOutfit(name: "Weekend denim", itemIDs: ids(["White cotton tee", "Straight leg jeans", "Denim jacket", "White sneakers"])))
        context.insert(SavedOutfit(name: "Mocha layers", itemIDs: ids(["Olive knit sweater", "Brown wide-leg pants", "Brown leather jacket", "Brown sneakers"])))
        try? context.save()
    }

    /// Cuts one garment out of the sample outfit photo (rect is 0…1 of the image)
    static func cropImage(_ image: UIImage?, to rect: CGRect) -> UIImage? {
        guard let cgImage = image?.cgImage else { return nil }
        let w = CGFloat(cgImage.width), h = CGFloat(cgImage.height)
        let pixels = CGRect(x: rect.minX * w, y: rect.minY * h, width: rect.width * w, height: rect.height * h).integral
        return cgImage.cropping(to: pixels).map { UIImage(cgImage: $0) }
    }

    /// Where each garment sits in `outfit_sample` (used by the intro animation)
    static let samplePhotoPieces: [(label: String, rect: CGRect)] = [
        ("Knit top · green", CGRect(x: 0.02, y: 0.01, width: 0.62, height: 0.37)),
        ("Trousers · brown", CGRect(x: 0.05, y: 0.37, width: 0.45, height: 0.61)),
        ("Jacket · leather", CGRect(x: 0.39, y: 0.39, width: 0.59, height: 0.35)),
        ("Sneakers", CGRect(x: 0.48, y: 0.82, width: 0.50, height: 0.13)),
    ]

    /// Fallback if an asset is missing: the garment's SF Symbol on a soft card
    static func placeholderImage(symbol: String, hex: String) -> Data {
        let size = CGSize(width: 300, height: 360)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor(red: 0.94, green: 0.92, blue: 0.87, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let config = UIImage.SymbolConfiguration(pointSize: 170, weight: .regular)
            if let glyph = UIImage(systemName: symbol, withConfiguration: config)?
                .withTintColor(UIColor(hex: hex), renderingMode: .alwaysOriginal) {
                glyph.draw(in: CGRect(x: (size.width - glyph.size.width) / 2,
                                      y: (size.height - glyph.size.height) / 2,
                                      width: glyph.size.width, height: glyph.size.height))
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
