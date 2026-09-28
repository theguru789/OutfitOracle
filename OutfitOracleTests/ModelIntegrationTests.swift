//
//  ModelIntegrationTests.swift
//  OutfitOracleTests
//
//  Runs the real bundled Core ML models (GarmentDetector, AttributeClassifier,
//  OutfitScorer) to catch bad exports.
//

import Testing
import UIKit
@testable import OutfitOracle

struct ModelIntegrationTests {

    @Test func allThreeModelsLoad() throws {
        _ = try GarmentDetectionService()
        #expect(OutfitEngine().usesModel)
    }

    @Test func scorerReturnsProbabilities() {
        let engine = OutfitEngine()
        let score = engine.modelScore([snap(.top, "white"), snap(.bottom, "blue", fabric: "denim"),
                                       snap(.shoes, "white", fabric: "leather")])
        #expect((0...1).contains(score))
    }

    @Test func scorerIsNotConstant() {
        let engine = OutfitEngine()
        let a = engine.modelScore([snap(.top, "white"), snap(.bottom, "navy")])
        let b = engine.modelScore([snap(.top, "red", pattern: "floral", fabric: "chiffon"),
                                   snap(.bottom, "green", pattern: "plaid", fabric: "leather"),
                                   snap(.accessory, "purple")])
        #expect(a != b)
    }

    /// outfit_sample: olive knit sweater, dark brown trousers, brown leather jacket, sneakers
    @Test func detectorFindsGarmentsInSamplePhoto() async throws {
        let service = try GarmentDetectionService()
        let image = try #require(UIImage(named: "outfit_sample"))
        let garments = try await service.detectGarments(in: image)
        let summary = garments.map { "\($0.detectorLabel)|\($0.color)|\($0.pattern)|\($0.fabric)|\($0.styleTag)" }

        let sweater = try #require(garments.first { $0.role == .top }, "\(summary)")
        #expect(sweater.color == "green", "\(summary)")
        #expect(sweater.fabric == "knit", "\(summary)")
        #expect(sweater.styleTag.hasPrefix("long_sleeve"), "\(summary)")

        let trousers = try #require(garments.first { $0.detectorLabel == "trousers" }, "\(summary)")
        #expect(trousers.color == "brown", "\(summary)")

        // The classifier must not give every crop identical attributes (the old export bug)
        #expect(Set(garments.map { "\($0.fabric)\($0.styleTag)" }).count > 1, "\(summary)")
        #expect(garments.allSatisfy { $0.image != nil })
    }

    /// A frame-filling single color reads as a close-up garment (the detector
    /// scores it ~0.6 "short_sleeve_top"), so a plain photo should give exactly
    /// one item for the user to keep or discard — never zero or duplicates.
    @Test func plainPhotoGivesExactlyOneItem() async throws {
        let service = try GarmentDetectionService()
        for color in [UIColor.systemTeal, .white, .black] {
            let garments = try await service.detectGarments(in: solidImage(color))
            #expect(garments.count == 1, "\(color)")
        }
    }

    @Test func bigPhotosAreDownsizedBeforeDetection() {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let big = UIGraphicsImageRenderer(size: CGSize(width: 4000, height: 3000), format: format).image { _ in }
        let small = GarmentDetectionService.normalized(big, maxSide: 1024)
        #expect(max(small.size.width, small.size.height) <= 1024)
    }
}
