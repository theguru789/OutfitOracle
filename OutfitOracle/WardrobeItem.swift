//
//  WardrobeItem.swift
//  OutfitOracle
//

import SwiftData
import SwiftUI

@Model
class WardrobeItem {
    var id: UUID
    var croppedImageData: Data
    var category: String
    var color: String
    var pattern: String
    var styleTag: String
    var fabricType: String
    var dateAdded: Date

    init(
        croppedImageData: Data,
        category: String,
        color: String = "unknown",
        pattern: String = "unknown",
        styleTag: String = "unknown",
        fabricType: String = "unknown"
    ) {
        self.id              = UUID()
        self.croppedImageData = croppedImageData
        self.category        = category
        self.color           = color
        self.pattern         = pattern
        self.styleTag        = styleTag
        self.fabricType      = fabricType
        self.dateAdded       = Date()
    }

    // Convenience: UIImage from stored data
    var croppedImage: UIImage? {
        UIImage(data: croppedImageData)
    }

    // Human-readable attribute summary
    var attributeSummary: String {
        "\(color) · \(pattern) · \(fabricType)"
    }
}
