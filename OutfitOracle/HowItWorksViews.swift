//
//  HowItWorksViews.swift
//  OutfitOracle
//
//  The short animated "simulation" shown in the intro, and the detailed
//  how-it-works guide it links to.
//

import SwiftUI

// MARK: - Short looping simulation (≈7 seconds)
/// Snap → AI finds each piece → outfit built from your closet → trend check.
/// Uses the bundled outfit photo so it looks like the real thing.
struct AppSimulationView: View {
    var height: CGFloat = 280

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var scanProgress: CGFloat = 0
    @State private var photo: UIImage?
    @State private var pieces: [UIImage] = []

    static let captions = [
        "1. Snap a photo of your clothes",
        "2. On-device AI finds each piece",
        "3. The Oracle builds outfits from your closet",
        "4. See which trends you already own",
    ]
    private let photoAspect: CGFloat = 736.0 / 1308.0

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.ooButter.opacity(0.6))

                Group {
                    switch step {
                    case 0, 1: scanAndDetect
                    case 2: outfitStep
                    default: trendStep
                    }
                }
                .padding(12)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            Text(Self.captions[step])
                .font(.headline)
                .foregroundColor(.ooBrown)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .id(step)
                .transition(.opacity)

            HStack(spacing: 6) {
                ForEach(0..<Self.captions.count, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? Color.ooBrown : Color.ooBrown.opacity(0.25))
                        .frame(width: i == step ? 18 : 6, height: 6)
                }
            }
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("How it works: " + Self.captions.joined(separator: ". "))
        .task { await run() }
    }

    // MARK: Steps

    private var scanAndDetect: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(photoAspect, contentMode: .fit)
                    .overlay {
                        GeometryReader { geo in
                            if step == 0 {
                                // Scanning line sweeping down the photo
                                LinearGradient(colors: [.clear, Color.yellow.opacity(0.8), .clear],
                                               startPoint: .top, endPoint: .bottom)
                                    .frame(height: 28)
                                    .offset(y: scanProgress * (geo.size.height - 28))
                            } else {
                                ForEach(SampleData.samplePhotoPieces.indices, id: \.self) { i in
                                    let piece = SampleData.samplePhotoPieces[i]
                                    let r = piece.rect
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.yellow, lineWidth: 2.5)
                                        .frame(width: r.width * geo.size.width, height: r.height * geo.size.height)
                                        .overlay(alignment: .topLeading) {
                                            Text(piece.label)
                                                .font(.system(size: 9, weight: .bold))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(Color.yellow)
                                                .foregroundColor(.ooDeepBrown)
                                                .cornerRadius(4)
                                                .offset(y: -12)
                                        }
                                        .position(x: r.midX * geo.size.width, y: r.midY * geo.size.height)
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                ProgressView()
            }
        }
    }

    private var outfitStep: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                VStack(spacing: 8) {
                    piece(0)
                    piece(1)
                }
                VStack(spacing: 8) {
                    piece(2)
                    piece(3)
                }
            }
            HStack {
                Text("93% style match")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ooBrown)
                    .foregroundColor(.ooLightText)
                    .cornerRadius(8)
                Label("Layered for a chilly day", systemImage: "leaf")
                    .font(.caption)
                    .foregroundColor(.ooBrown)
                Spacer(minLength: 0)
            }
        }
    }

    private var trendStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mocha Layers")
                .font(.title3.bold())
            HStack(spacing: 6) {
                ForEach(["#7B5236", "#A67B5B", "#E8DCC8", "#F5F5F0"], id: \.self) { ColorSwatch(hex: $0, size: 20) }
            }
            HStack(spacing: 6) {
                ForEach(0..<min(pieces.count, 4), id: \.self) { i in
                    Image(uiImage: pieces[i])
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 70)
                        .background(Color.white.opacity(0.55))
                        .cornerRadius(10)
                }
            }
            ProgressView(value: 1).tint(.ooBrown)
            Text("You own 4 of 4 pieces")
                .font(.subheadline.bold())
            Label("No shopping needed. Re-wear what you have!", systemImage: "leaf.fill")
                .font(.caption)
        }
        .foregroundColor(.ooBrown)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func piece(_ i: Int) -> some View {
        Group {
            if i < pieces.count {
                Image(uiImage: pieces[i]).resizable().scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.55))
        .cornerRadius(12)
    }

    // MARK: Animation loop

    private func run() async {
        let image = UIImage(named: "outfit_sample")
        photo = image
        pieces = SampleData.samplePhotoPieces.compactMap { SampleData.cropImage(image, to: $0.rect) }

        while !Task.isCancelled {
            for s in 0..<Self.captions.count {
                withAnimation(.easeInOut(duration: 0.45)) { step = s }
                if s == 0 && !reduceMotion {
                    scanProgress = 0
                    withAnimation(.easeInOut(duration: 1.4)) { scanProgress = 1 }
                }
                try? await Task.sleep(for: .seconds(s == 0 ? 1.6 : 1.9))
                if Task.isCancelled { return }
            }
        }
    }
}

// MARK: - Detailed guide
struct HowItWorksGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ooCream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AppSimulationView(height: 300)

                        section("camera.viewfinder", "1. Snap your closet", .ooBlue, [
                            "Open the Camera tab and tap Upload (from your photos) or Take Photo.",
                            "On-device AI finds every garment in the picture: tops, bottoms, dresses and outerwear.",
                            "A second model reads each piece's pattern, fabric, sleeves and fit, and the app measures its main color.",
                            "Check the results in the review screen. Fix anything it got wrong, then tap Save to closet.",
                            "Shoes and accessories: tap \"Add shoes or accessories manually\" and pick the type yourself.",
                        ], tip: "Best results: good light, a plain background, and the clothes laid flat or on a hanger.")

                        section("hanger", "2. Your closet", .ooButter, [
                            "Filter by type, and tap any piece to see its details or edit them.",
                            "Tap \"Wore it today\" to track how often you wear each piece.",
                            "A moon badge means a piece hasn't been worn in 30+ days. The Oracle will suggest it more.",
                            "Done with something? \"Not wearing this anymore?\" points you to selling or donating it before it's archived.",
                        ])

                        section("sparkles", "3. Outfits made for you", Color.ooPink.opacity(0.6), [
                            "\"What should I wear today?\" builds outfits only from clothes you own.",
                            "A model trained on thousands of stylist-made outfits gives each combination a style-match score.",
                            "Outfits also get a boost for forgotten pieces, today's weather (layers when it's cold) and your favorite colors. Looks you wore in the last week are avoided.",
                            "Tap an outfit to see a big preview. Tap \"Wear this\" to log it, or share it.",
                        ])

                        section("leaf", "4. Trends & complete the look", .ooBlue, [
                            "Explore trends shows this season's looks and how many of the pieces you already own.",
                            "\"Build it from my closet\" makes that trend using your own clothes.",
                            "If a piece is missing, Outfit Oracle shows secondhand shops first (thredUP, Depop, Poshmark, local thrift), then sustainable brands. Never fast fashion.",
                        ])

                        section("bubble.left.and.bubble.right", "5. Ask the Oracle", .ooLatte, [
                            "Ask things like \"What should I wear today?\", \"What's trending?\" or \"What have I forgotten about?\"",
                            "On iPhone 15 Pro and newer, answers come from Apple's on-device AI. Other iPhones use a simpler built-in Oracle.",
                        ])

                        section("chart.bar.fill", "6. Your impact", .ooButter, [
                            "Stats show your re-wears, the trend pieces you didn't need to buy, and how much of your closet you actually use.",
                        ])

                        section("lock.shield", "7. Private by design", Color.ooPink.opacity(0.6), [
                            "Everything stays on your iPhone. There's no account and no cloud upload.",
                        ])
                    }
                    .padding()
                }
            }
            .navigationTitle("How Outfit Oracle works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.ooBrown)
    }

    private func section(_ symbol: String, _ title: String, _ color: Color, _ points: [String], tip: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.headline)
            ForEach(points, id: \.self) { point in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("•")
                    Text(point).fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline)
            }
            if let tip {
                Label(tip, systemImage: "lightbulb")
                    .font(.caption.bold())
                    .padding(8)
                    .background(Color.ooCream.opacity(0.8))
                    .cornerRadius(10)
            }
        }
        .foregroundColor(.ooDeepBrown)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color)
        .cornerRadius(20)
    }
}
