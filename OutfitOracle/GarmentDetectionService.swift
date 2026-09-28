//
//  GarmentDetectionService.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 7/18/26.
//
//  Two-pass on-device pipeline:
//    Pass 1 — GarmentDetector (YOLOv8n, DeepFashion2) finds + crops each garment
//    Pass 2 — AttributeClassifier (MobileNetV3, 26 DeepFashion attrs) labels each crop
//  Plus ColorExtractor for the dominant color (not one of the 26 attributes).
//

import Vision
import CoreML
import UIKit

/// Plain value result so it can cross from the background inference task to the UI
nonisolated struct DetectedGarment: Identifiable, Sendable {
    let id = UUID()
    let imageData: Data
    let detectorLabel: String
    let role: GarmentRole
    let color: String
    let colorHex: String
    let pattern: String
    let fabric: String
    let styleTag: String
    let confidence: Float
    /// false when nothing was detected and the whole photo is used as one item
    let wasDetected: Bool

    var image: UIImage? { UIImage(data: imageData) }
}

nonisolated final class GarmentDetectionService: @unchecked Sendable {

    // ── Models ────────────────────────────────────────────────────────────────
    private let detectorModel: VNCoreMLModel
    private let classifierModel: VNCoreMLModel

    // ── Attribute labels (must match train_attributes.py order) ──────────────
    static let ATTRIBUTES = [
        "floral", "graphic", "striped", "embroidered", "pleated", "solid", "lattice",
        "long_sleeve", "short_sleeve", "sleeveless",
        "maxi_length", "mini_length", "no_dress",
        "crew_neckline", "v_neckline", "square_neckline", "no_neckline",
        "denim", "chiffon", "cotton", "leather", "faux", "knit",
        "tight", "loose", "conventional"
    ]

    static let PATTERN_INDICES  = Array(0...6)    // floral → lattice
    static let SLEEVE_INDICES   = Array(7...9)    // long_sleeve → sleeveless
    static let FABRIC_INDICES   = Array(17...22)  // denim → knit
    static let FIT_INDICES      = Array(23...25)  // tight → conventional

    static let CONFIDENCE_THRESHOLD: Float = 0.5
    static let DETECTION_THRESHOLD: Float  = 0.4
    static let MAX_INPUT_SIDE: CGFloat     = 1024   // keeps older iPhones fast

    // ── Init ──────────────────────────────────────────────────────────────────
    init() throws {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        self.detectorModel   = try VNCoreMLModel(for: Self.loadModel("GarmentDetector", config: config))
        self.classifierModel = try VNCoreMLModel(for: Self.loadModel("AttributeClassifier", config: config))
    }

    private static func loadModel(_ name: String, config: MLModelConfiguration) throws -> MLModel {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") else {
            throw DetectionError.modelNotLoaded
        }
        return try MLModel(contentsOf: url, configuration: config)
    }

    // ── Main entry point ──────────────────────────────────────────────────────
    /// Runs both inference passes off the main thread and returns one result per garment
    @concurrent
    func detectGarments(in image: UIImage) async throws -> [DetectedGarment] {
        let prepared = Self.normalized(image, maxSide: Self.MAX_INPUT_SIDE)
        guard let cgImage = prepared.cgImage else {
            throw DetectionError.invalidImage
        }

        // Pass 1 — detect and crop garments
        var crops = try runDetection(on: cgImage)
        let detectedAny = !crops.isEmpty

        // Nothing found (e.g. a flat-lay close-up): treat the whole photo as one item
        if crops.isEmpty {
            crops = [(cgImage, "top", 0)]
        }

        // Pass 2 — classify attributes + color for each crop
        return try crops.map { crop, label, confidence in
            try classifyAttributes(crop: crop, label: label,
                                   confidence: confidence, wasDetected: detectedAny)
        }
    }

    // ── Pass 1: Detection ─────────────────────────────────────────────────────
    private func runDetection(on cgImage: CGImage) throws -> [(CGImage, String, Float)] {
        let request = VNCoreMLRequest(model: detectorModel)
        request.imageCropAndScaleOption = .scaleFill
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])

        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return []
        }

        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)
        var crops: [(CGImage, String, Float)] = []

        for obs in results where obs.confidence > Self.DETECTION_THRESHOLD {
            // The detector returns class names ("long_sleeve_top"), not indices
            let label = obs.labels.first?.identifier ?? "top"

            // Flip Y-axis (Vision is bottom-left, UIKit is top-left) + pad 5%
            let bbox = obs.boundingBox
            let pixelRect = CGRect(
                x: bbox.minX * imgW,
                y: (1 - bbox.maxY) * imgH,
                width: bbox.width * imgW,
                height: bbox.height * imgH
            )
            .insetBy(dx: -bbox.width * imgW * 0.05, dy: -bbox.height * imgH * 0.05)
            .intersection(CGRect(x: 0, y: 0, width: imgW, height: imgH))
            .integral

            if let cropped = cgImage.cropping(to: pixelRect) {
                crops.append((cropped, label, obs.confidence))
            }
        }
        return crops
    }

    // ── Pass 2: Attribute Classification ─────────────────────────────────────
    private func classifyAttributes(
        crop: CGImage,
        label: String,
        confidence: Float,
        wasDetected: Bool
    ) throws -> DetectedGarment {

        let cropImage = UIImage(cgImage: crop)
        let imageData = cropImage.jpegData(compressionQuality: 0.8) ?? Data()
        let (colorName, colorHex) = ColorExtractor.dominantColor(of: cropImage)

        let request = VNCoreMLRequest(model: classifierModel)
        request.imageCropAndScaleOption = .scaleFill  // training used Resize((224, 224))
        try VNImageRequestHandler(cgImage: crop, options: [:]).perform([request])

        var pattern = "unknown", fabric = "unknown", styleTag = "casual"

        if let results = request.results as? [VNCoreMLFeatureValueObservation],
           let scores  = results.first?.featureValue.multiArrayValue {
            pattern = Self.userPattern(Self.topAttribute(scores: scores, indices: Self.PATTERN_INDICES))
            fabric  = Self.userFabric(Self.topAttribute(scores: scores, indices: Self.FABRIC_INDICES))
            let sleeve = Self.topAttribute(scores: scores, indices: Self.SLEEVE_INDICES)
            let fit    = Self.topAttribute(scores: scores, indices: Self.FIT_INDICES)
            let tag    = [sleeve, fit].filter { $0 != "unknown" }.joined(separator: "_")
            if !tag.isEmpty { styleTag = tag }
        }

        return DetectedGarment(
            imageData: imageData,
            detectorLabel: label,
            role: GarmentRole(detectorLabel: label),
            color: colorName,
            colorHex: colorHex,
            pattern: pattern,
            fabric: fabric,
            styleTag: styleTag,
            confidence: confidence,
            wasDetected: wasDetected
        )
    }

    // ── Helper: pick highest scoring attribute from a group ───────────────────
    static func topAttribute(scores: MLMultiArray, indices: [Int]) -> String {
        var best: (index: Int, score: Float) = (0, 0)
        for i in indices where i < scores.count {
            let score = scores[i].floatValue
            if score > best.score {
                best = (i, score)
            }
        }
        guard best.score > CONFIDENCE_THRESHOLD else { return "unknown" }
        return ATTRIBUTES[best.index]
    }

    /// DeepFashion pattern names → the pattern names shown in the app
    static func userPattern(_ raw: String) -> String {
        switch raw {
        case "lattice": "plaid"
        default: raw
        }
    }

    /// DeepFashion fabric names → the fabric names shown in the app
    static func userFabric(_ raw: String) -> String {
        switch raw {
        case "faux": "leather"
        default: raw
        }
    }

    /// Fixes camera orientation (cgImage ignores it) and downsizes big photos
    static func normalized(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxSide / max(longest, 1))
        if scale == 1, image.imageOrientation == .up { return image }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // ── Errors ────────────────────────────────────────────────────────────────
    enum DetectionError: LocalizedError {
        case invalidImage
        case modelNotLoaded

        var errorDescription: String? {
            switch self {
            case .invalidImage: "That photo couldn't be read. Try another one."
            case .modelNotLoaded: "The clothing models couldn't be loaded."
            }
        }
    }
}
