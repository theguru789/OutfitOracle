//
//  CutoutService.swift
//  OutfitOracle
//
//  Removes the background from garment photos (Apple Vision "subject lifting",
//  iOS 17+, on-device) so outfits can be shown as one combined picture.
//

import CoreImage
import SwiftData
import UIKit
import Vision

nonisolated enum CutoutService {

    /// PNG of just the garment(s), cropped to them; nil if no subject was found
    @concurrent
    static func cutout(from data: Data) async -> Data? {
        guard let cgImage = UIImage(data: data)?.cgImage else { return nil }
        let handler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return nil }
            let buffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances, from: handler, croppedToInstancesExtent: true)
            let image = CIImage(cvPixelBuffer: buffer)
            guard let output = CIContext().createCGImage(image, from: image.extent) else { return nil }
            return UIImage(cgImage: output).pngData()
        } catch {
            return nil   // e.g. not supported in the Simulator — the plain photo is used instead
        }
    }

    /// Makes cutouts for items that don't have one yet (new photos, older installs)
    @MainActor
    static func backfill(_ context: ModelContext, limit: Int = 40) async {
        let descriptor = FetchDescriptor<WardrobeItem>(predicate: #Predicate { $0.cutoutImageData == nil })
        guard let items = try? context.fetch(descriptor), !items.isEmpty else { return }
        for item in items.prefix(limit) {
            // If lifting fails, store the photo itself so we don't retry every launch
            item.cutoutImageData = await cutout(from: item.croppedImageData) ?? item.croppedImageData
        }
        try? context.save()
    }
}
