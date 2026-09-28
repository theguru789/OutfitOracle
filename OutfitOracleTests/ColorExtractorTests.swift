//
//  ColorExtractorTests.swift
//  OutfitOracleTests
//

import Testing
import UIKit
@testable import OutfitOracle

struct ColorExtractorTests {

    @Test(arguments: [
        (UIColor(red: 0.78, green: 0.12, blue: 0.12, alpha: 1), "red"),
        (UIColor(red: 0.10, green: 0.16, blue: 0.34, alpha: 1), "navy"),
        (UIColor(white: 0.05, alpha: 1), "black"),
        (UIColor(white: 0.95, alpha: 1), "white"),
        (UIColor(red: 0.25, green: 0.52, blue: 0.30, alpha: 1), "green"),
        (UIColor(red: 0.45, green: 0.30, blue: 0.20, alpha: 1), "brown"),
        // Real dark garment colors measured from the outfit_sample photo
        (UIColor(red: 0.23, green: 0.22, blue: 0.15, alpha: 1), "green"),   // olive knit sweater
        (UIColor(red: 0.16, green: 0.11, blue: 0.10, alpha: 1), "brown"),   // dark brown trousers
        (UIColor(red: 0.26, green: 0.23, blue: 0.20, alpha: 1), "brown"),   // brown leather jacket
        (UIColor(red: 0.30, green: 0.40, blue: 0.55, alpha: 1), "blue"),    // denim
        (UIColor(red: 0.90, green: 0.48, blue: 0.18, alpha: 1), "orange"),
        (UIColor(red: 0.92, green: 0.80, blue: 0.25, alpha: 1), "yellow"),
        (UIColor(red: 0.48, green: 0.30, blue: 0.60, alpha: 1), "purple"),
        (UIColor(red: 0.92, green: 0.60, blue: 0.72, alpha: 1), "pink"),
        (UIColor(white: 0.55, alpha: 1), "grey"),
        (UIColor(red: 0.93, green: 0.90, blue: 0.82, alpha: 1), "white"),   // cream
    ])
    func namesSolidColors(color: UIColor, expected: String) {
        #expect(ColorExtractor.dominantColor(of: solidImage(color)).name == expected)
    }

    @Test func alwaysReturnsAScorerColor() {
        for _ in 0..<50 {
            let random = UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
            let name = ColorExtractor.dominantColor(of: solidImage(random)).name
            #expect(ScorerEncoder.colors.contains(name), "\(random) → \(name)")
        }
    }

    @Test func dominantClusterWinsOverSmallDetails() {
        // Mostly red garment with a small white logo in the middle
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100), format: format).image { ctx in
            UIColor(red: 0.78, green: 0.12, blue: 0.12, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 42, y: 42, width: 16, height: 16))
        }
        #expect(ColorExtractor.dominantColor(of: image).name == "red")
    }

    @Test func hexIsFormattedLikeASwatch() {
        #expect(ColorExtractor.hexString(.init(r: 1, g: 0, b: 0.5)) == "#FF0080")
    }
}
