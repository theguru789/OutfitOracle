//
//  ShareOutfit.swift
//  OutfitOracle
//
//  Turns an outfit into a shareable image card (a mini mood board) —
//  "styled from my own closet" is a nice way to spread the re-wear idea.
//

import SwiftUI

/// The image that gets shared: item photos in a grid on the app's cream card
struct OutfitShareCard: View {
    let outfit: Outfit
    let lookup: [UUID: WardrobeItem]
    var trendName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                Text("Outfit Oracle")
                    .font(.headline.bold())
                Spacer()
                Text("\(outfit.percent)% match")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.ooBrown)
                    .foregroundColor(.ooLightText)
                    .cornerRadius(10)
            }
            .foregroundColor(.ooBrown)

            OutfitFlatLay(outfit: outfit, lookup: lookup, height: 380)

            if let trendName {
                Text("On trend: \(trendName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.ooBrown)
            }
            Label("Styled 100% from my own closet", systemImage: "leaf.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.ooBrown)
        }
        .padding(20)
        .frame(width: 360)
        .background(Color.ooButter)
        .cornerRadius(28)
        .padding(12)
        .background(Color.ooCream)
    }
}

/// Share button that renders the card to an image on demand
struct ShareOutfitButton: View {
    let outfit: Outfit
    let lookup: [UUID: WardrobeItem]
    var trendName: String?

    var body: some View {
        if let image = renderedImage {
            ShareLink(
                item: image,
                subject: Text("My outfit from Outfit Oracle"),
                message: Text("Styled 100% from my own closet 🌱"),
                preview: SharePreview("My Outfit Oracle look", image: image)
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.subheadline.bold())
                    .foregroundColor(.ooBrown)
            }
        }
    }

    @MainActor
    private var renderedImage: Image? {
        let renderer = ImageRenderer(content: OutfitShareCard(outfit: outfit, lookup: lookup, trendName: trendName))
        renderer.scale = 2   // ~750px wide: crisp for social posts, cheap on older phones
        return renderer.uiImage.map { Image(uiImage: $0) }
    }
}
