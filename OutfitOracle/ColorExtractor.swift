//
//  ColorExtractor.swift
//  OutfitOracle
//
//  Finds a garment's dominant color and snaps it to one of the 12 color
//  names the OutfitScorer was trained on (train_scorer.py COLORS).
//

import UIKit

nonisolated enum ColorExtractor {

    struct RGB: Equatable {
        var r: Double, g: Double, b: Double
    }

    /// Returns (color name, hex of the actual dominant color)
    static func dominantColor(of image: UIImage) -> (name: String, hex: String) {
        guard let cgImage = image.cgImage else { return ("unknown", "#8E8E8E") }
        let pixels = centerPixels(of: cgImage, side: 32, cropFraction: 0.6)
        guard !pixels.isEmpty else { return ("unknown", "#8E8E8E") }

        let dominant = kMeansDominant(pixels, k: 3)
        return (nearestName(to: dominant), hexString(dominant))
    }

    // MARK: - Pixel sampling
    /// Draws the center `cropFraction` of the image into a small bitmap and returns its pixels
    static func centerPixels(of cgImage: CGImage, side: Int, cropFraction: CGFloat) -> [RGB] {
        let w = CGFloat(cgImage.width), h = CGFloat(cgImage.height)
        let cropRect = CGRect(
            x: w * (1 - cropFraction) / 2,
            y: h * (1 - cropFraction) / 2,
            width: w * cropFraction,
            height: h * cropFraction
        ).integral
        guard let cropped = cgImage.cropping(to: cropRect) else { return [] }

        var buffer = [UInt8](repeating: 0, count: side * side * 4)
        guard let context = CGContext(
            data: &buffer,
            width: side, height: side,
            bitsPerComponent: 8, bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        context.interpolationQuality = .medium
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: side, height: side))

        var pixels: [RGB] = []
        pixels.reserveCapacity(side * side)
        for i in stride(from: 0, to: buffer.count, by: 4) where buffer[i + 3] > 0 {
            pixels.append(RGB(r: Double(buffer[i]) / 255,
                              g: Double(buffer[i + 1]) / 255,
                              b: Double(buffer[i + 2]) / 255))
        }
        return pixels
    }

    // MARK: - Tiny k-means: centre of the biggest cluster
    static func kMeansDominant(_ pixels: [RGB], k: Int, iterations: Int = 8) -> RGB {
        guard pixels.count > k else { return average(pixels) }
        var centers = (0..<k).map { pixels[$0 * pixels.count / k] }
        var assignment = [Int](repeating: 0, count: pixels.count)

        for _ in 0..<iterations {
            for (i, p) in pixels.enumerated() {
                assignment[i] = centers.indices.min { distSq(p, centers[$0]) < distSq(p, centers[$1]) } ?? 0
            }
            for c in 0..<k {
                let members = pixels.indices.filter { assignment[$0] == c }.map { pixels[$0] }
                if !members.isEmpty { centers[c] = average(members) }
            }
        }
        let counts = (0..<k).map { c in assignment.filter { $0 == c }.count }
        let biggest = counts.indices.max { counts[$0] < counts[$1] } ?? 0
        return centers[biggest]
    }

    // MARK: - Name the color using lightness / chroma / hue (CIE LCh)
    /// Garment photos are often dark and low-saturation (olive knits, brown denim),
    /// so plain nearest-swatch matching calls almost everything "black". Naming by
    /// hue angle + lightness matches how people describe clothes.
    static func nearestName(to rgb: RGB) -> String {
        let lab = toLab(rgb)
        let L = lab.l
        let chroma = (lab.a * lab.a + lab.b * lab.b).squareRoot()
        var hue = atan2(lab.b, lab.a) * 180 / .pi
        if hue < 0 { hue += 360 }

        // Neutrals: very dark, or little color relative to lightness
        if L < 10 { return "black" }
        if chroma / (L + 10) < 0.15 {
            if L < 30 { return "black" }
            if L < 80 { return "grey" }
            return "white"
        }

        switch hue {
        case ..<20, 340...:
            return L > 60 ? "pink" : "red"
        case 20..<55:
            if chroma > 50 { return "red" }
            return L < 55 ? "brown" : "pink"
        case 55..<80:
            if L < 55 { return "brown" }
            return chroma > 45 ? "orange" : "brown"
        case 80..<105:
            return L < 55 ? "green" : "yellow"       // dark yellow-green = olive
        case 105..<200:
            return "green"
        case 200..<300:
            if L < 30 { return chroma < 8 ? "black" : "navy" }
            return "blue"
        default: // 300..<340
            return L < 70 ? "purple" : "pink"
        }
    }

    // MARK: - Math helpers
    static func average(_ pixels: [RGB]) -> RGB {
        guard !pixels.isEmpty else { return RGB(r: 0.5, g: 0.5, b: 0.5) }
        let n = Double(pixels.count)
        return RGB(r: pixels.reduce(0) { $0 + $1.r } / n,
                   g: pixels.reduce(0) { $0 + $1.g } / n,
                   b: pixels.reduce(0) { $0 + $1.b } / n)
    }

    static func distSq(_ a: RGB, _ b: RGB) -> Double {
        let dr = a.r - b.r, dg = a.g - b.g, db = a.b - b.b
        return dr * dr + dg * dg + db * db
    }

    static func hexString(_ c: RGB) -> String {
        String(format: "#%02X%02X%02X",
               Int((c.r * 255).rounded()), Int((c.g * 255).rounded()), Int((c.b * 255).rounded()))
    }

    static func toLab(_ c: RGB) -> (l: Double, a: Double, b: Double) {
        func linear(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        let r = linear(c.r), g = linear(c.g), b = linear(c.b)
        let x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
        let y = (r * 0.2126 + g * 0.7152 + b * 0.0722)
        let z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883
        func f(_ t: Double) -> Double { t > 0.008856 ? cbrt(t) : (7.787 * t + 16 / 116) }
        let fx = f(x), fy = f(y), fz = f(z)
        return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))
    }
}
