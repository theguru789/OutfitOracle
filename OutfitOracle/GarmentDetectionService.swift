//
//  GarmentDetectionService.swift
//  OutfitOracle
//

import Vision
import CoreML
import UIKit
import SwiftData

class GarmentDetectionService {

    // ── Models ────────────────────────────────────────────────────────────────
    private let detectorModel: VNCoreMLModel
    private let classifierModel: VNCoreMLModel

    // ── Attribute labels (must match train_attributes.py order) ──────────────
    let ATTRIBUTES = [
        "floral", "graphic", "striped", "embroidered", "pleated", "solid", "lattice",
        "long_sleeve", "short_sleeve", "sleeveless",
        "maxi_length", "mini_length", "no_dress",
        "crew_neckline", "v_neckline", "square_neckline", "no_neckline",
        "denim", "chiffon", "cotton", "leather", "faux", "knit",
        "tight", "loose", "conventional"
    ]

    let PATTERN_INDICES  = Array(0...6)    // floral → lattice
    let SLEEVE_INDICES   = Array(7...9)    // long_sleeve → sleeveless
    let FABRIC_INDICES   = Array(17...22)  // denim → knit
    let FIT_INDICES      = Array(23...25)  // tight → conventional

    let CONFIDENCE_THRESHOLD: Float = 0.5

    // ── Category names (must match deepfashion2.yaml order) ──────────────────
    let CATEGORIES = [
        "top", "top", "outerwear", "outerwear",
        "vest", "sling", "shorts", "trousers",
        "skirt", "dress", "dress", "dress", "dress"
    ]

    // ── Init ──────────────────────────────────────────────────────────────────
    init() throws {
        let detector   = try GarmentDetector(configuration: MLModelConfiguration())
        let classifier = try AttributeClassifier(configuration: MLModelConfiguration())
        self.detectorModel   = try VNCoreMLModel(for: detector.model)
        self.classifierModel = try VNCoreMLModel(for: classifier.model)
    }

    // ── Main entry point ──────────────────────────────────────────────────────
    /// Runs both inference passes on a UIImage and returns WardrobeItems
    func detectGarments(in image: UIImage) async throws -> [WardrobeItem] {
        guard let cgImage = image.cgImage else {
            throw DetectionError.invalidImage
        }

        // Pass 1 — detect and crop garments
        let crops = try await runDetection(on: cgImage, sourceImage: image)

        // Pass 2 — classify attributes for each crop
        var items: [WardrobeItem] = []
        for (cropImage, category) in crops {
            let item = try await classifyAttributes(
                cropImage: cropImage,
                category: category
            )
            items.append(item)
        }
        return items
    }

    // ── Pass 1: Detection ─────────────────────────────────────────────────────
    private func runDetection(
        on cgImage: CGImage,
        sourceImage: UIImage
    ) async throws -> [(UIImage, String)] {

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: detectorModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                var crops: [(UIImage, String)] = []

                for obs in results {
                    guard obs.confidence > 0.4 else { continue }

                    // Get category name
                    let labelIndex = Int(obs.labels.first?.identifier ?? "0") ?? 0
                    let category   = labelIndex < self.CATEGORIES.count
                        ? self.CATEGORIES[labelIndex] : "top"

                    // Flip Y-axis (Vision is bottom-left, UIKit is top-left)
                    let bbox = obs.boundingBox
                    let flipped = CGRect(
                        x: bbox.minX,
                        y: 1 - bbox.maxY,
                        width: bbox.width,
                        height: bbox.height
                    )

                    // Convert normalised rect to pixel rect
                    let imgW = CGFloat(cgImage.width)
                    let imgH = CGFloat(cgImage.height)
                    let pixelRect = CGRect(
                        x: flipped.minX * imgW,
                        y: flipped.minY * imgH,
                        width: flipped.width * imgW,
                        height: flipped.height * imgH
                    )

                    // Crop
                    if let cropped = cgImage.cropping(to: pixelRect) {
                        crops.append((UIImage(cgImage: cropped), category))
                    }
                }

                continuation.resume(returning: crops)
            }

            request.imageCropAndScaleOption = .scaleFill
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // ── Pass 2: Attribute Classification ─────────────────────────────────────
    private func classifyAttributes(
        cropImage: UIImage,
        category: String
    ) async throws -> WardrobeItem {

        guard let cgImage = cropImage.cgImage else {
            throw DetectionError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: classifierModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                // Extract 26 attribute scores
                guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                      let scores  = results.first?.featureValue.multiArrayValue else {
                    // Return basic item if classification fails
                    let item = WardrobeItem(
                        croppedImageData: cropImage.jpegData(compressionQuality: 0.8) ?? Data(),
                        category: category
                    )
                    continuation.resume(returning: item)
                    return
                }

                // Parse attributes above confidence threshold
                let pattern  = self.topAttribute(scores: scores, indices: self.PATTERN_INDICES)
                let sleeve   = self.topAttribute(scores: scores, indices: self.SLEEVE_INDICES)
                let fabric   = self.topAttribute(scores: scores, indices: self.FABRIC_INDICES)
                let fit      = self.topAttribute(scores: scores, indices: self.FIT_INDICES)

                let styleTag = [sleeve, fit].filter { $0 != "unknown" }.joined(separator: "_")

                let item = WardrobeItem(
                    croppedImageData: cropImage.jpegData(compressionQuality: 0.8) ?? Data(),
                    category: category,
                    color:    "unknown", // color not in our 26 attrs — Vision can help later
                    pattern:  pattern,
                    styleTag: styleTag.isEmpty ? "casual" : styleTag,
                    fabricType: fabric
                )
                continuation.resume(returning: item)
            }

            request.imageCropAndScaleOption = .centerCrop
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // ── Helper: pick highest scoring attribute from a group ───────────────────
    private func topAttribute(scores: MLMultiArray, indices: [Int]) -> String {
        var best: (index: Int, score: Float) = (0, 0)
        for i in indices {
            let score = scores[i].floatValue
            if score > best.score {
                best = (i, score)
            }
        }
        guard best.score > CONFIDENCE_THRESHOLD else { return "unknown" }
        return ATTRIBUTES[best.index]
    }

    // ── Errors ────────────────────────────────────────────────────────────────
    enum DetectionError: Error {
        case invalidImage
        case modelNotLoaded
    }
}