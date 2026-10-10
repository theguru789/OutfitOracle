//
//  SharedViews.swift
//  OutfitOracle
//
//  Pieces reused across Home, Trends, Chat and Stats.
//

import SafariServices
import SwiftData
import SwiftUI

// MARK: - In-app Safari for shop / donate links
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor(Color.ooBrown)
        return vc
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

extension View {
    func safariSheet(url: Binding<URL?>) -> some View {
        sheet(item: url) { SafariView(url: $0).ignoresSafeArea() }
    }
}

// MARK: - Outfit card: flat-lay preview + score + reasons (tap for a big preview)
struct OutfitCard: View {
    let outfit: Outfit
    let lookup: [UUID: WardrobeItem]
    var background: Color = .ooButter
    var previewHeight: CGFloat = 240

    @State private var showPreview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showPreview = true
            } label: {
                OutfitFlatLay(outfit: outfit, lookup: lookup, height: previewHeight)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption.bold())
                            .padding(7)
                            .background(Color.ooCream.opacity(0.9))
                            .clipShape(Circle())
                            .padding(8)
                            .accessibilityHidden(true)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Outfit preview: " + outfit.items.compactMap { lookup[$0.id]?.name }.joined(separator: ", "))
            .accessibilityHint("Opens a bigger preview")

            HStack {
                Text("\(outfit.percent)%")
                    .font(.headline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.ooBrown)
                    .foregroundColor(.ooLightText)
                    .cornerRadius(12)
                Text("style match")
                    .font(.caption)
                Spacer()
            }

            ForEach(outfit.reasons.dropFirst(), id: \.self) { reason in
                Label(reason, systemImage: "leaf")
                    .font(.caption)
            }
        }
        .foregroundColor(.ooBrown)
        .padding()
        .background(background)
        .cornerRadius(25)
        .sheet(isPresented: $showPreview) {
            OutfitPreviewSheet(outfit: outfit, lookup: lookup)
        }
    }
}

// MARK: - Outfit picture: every piece cut out and arranged on one canvas
/// Like a Pinterest outfit board: the top sits above the bottom (or one dress),
/// with the jacket, accessory and shoes alongside — all on a single picture.
/// Uses each item's background-removed cutout when available.
struct OutfitFlatLay: View {
    let outfit: Outfit
    let lookup: [UUID: WardrobeItem]
    var height: CGFloat = 240

    var body: some View {
        OutfitCollage(items: outfit.items.compactMap { lookup[$0.id] }, height: height)
    }
}

struct OutfitCollage: View {
    let items: [WardrobeItem]
    var height: CGFloat = 240

    private func first(_ role: GarmentRole) -> WardrobeItem? { items.first { $0.role == role } }

    var body: some View {
        let dress = first(.dress), top = first(.top), bottom = first(.bottom)
        let layer = first(.outerwear), shoes = first(.shoes), extra = first(.accessory)
        let hasSide = layer != nil || shoes != nil || extra != nil

        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let mainW = hasSide ? w * 0.56 : w * 0.8
            let mainX = hasSide ? w * 0.31 : w * 0.5
            let sideX = w * 0.76, sideW = w * 0.42

            ZStack {
                Color.ooCream
                // Main column: dress, or top over bottom (slightly overlapping, like a flat-lay)
                if let dress {
                    piece(dress, width: mainW, height: h * 0.9).position(x: mainX, y: h * 0.5)
                } else {
                    if let bottom { piece(bottom, width: mainW * 0.85, height: h * 0.56).position(x: mainX, y: h * 0.69) }
                    if let top { piece(top, width: mainW, height: h * 0.46).position(x: mainX, y: h * 0.27) }
                }
                // Side column: layer on top, accessory in the middle, shoes at the bottom
                if let layer { piece(layer, width: sideW, height: h * 0.46).position(x: sideX, y: h * 0.26) }
                if let extra { piece(extra, width: sideW * 0.62, height: h * 0.18).position(x: sideX, y: h * 0.58) }
                if let shoes { piece(shoes, width: sideW * 0.8, height: h * 0.24).position(x: sideX, y: h * 0.84) }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Outfit picture: " + items.map(\.name).joined(separator: ", "))
    }

    private func piece(_ item: WardrobeItem, width: CGFloat, height: CGFloat) -> some View {
        Group {
            if let image = item.cutoutImage {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                Image(systemName: item.role.symbol)
                    .font(.largeTitle)
                    .foregroundColor(Color(hex: item.colorHex))
            }
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}

// MARK: - Full-screen outfit preview
struct OutfitPreviewSheet: View {
    let outfit: Outfit
    let lookup: [UUID: WardrobeItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ooCream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        OutfitFlatLay(outfit: outfit, lookup: lookup, height: 440)

                        HStack {
                            Text("\(outfit.percent)% style match")
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.ooBrown)
                                .foregroundColor(.ooLightText)
                                .cornerRadius(12)
                            Spacer()
                            ShareOutfitButton(outfit: outfit, lookup: lookup)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(outfit.items) { snap in
                                if let item = lookup[snap.id] {
                                    HStack(spacing: 8) {
                                        ColorSwatch(hex: item.colorHex, size: 12)
                                        Text(item.name).font(.subheadline.bold())
                                        Spacer()
                                        Text(item.role.singular.capitalizedFirst).font(.caption)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.ooButter)
                        .cornerRadius(18)

                        ForEach(outfit.reasons.dropFirst(), id: \.self) { reason in
                            Label(reason, systemImage: "leaf").font(.subheadline)
                        }
                    }
                    .foregroundColor(.ooBrown)
                    .padding()
                }
            }
            .navigationTitle("Outfit preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.ooBrown)
    }
}

// MARK: - Shop links for a missing trend piece
struct ShopLinksView: View {
    let slot: TrendSlot
    var onOpen: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: slot.role.symbol)
                Text(slot.searchTerm.capitalizedFirst)
                    .font(.headline)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ShopService.links(for: slot)) { link in
                        Button {
                            onOpen(link.url)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Label(link.store, systemImage: link.symbol)
                                    .font(.caption.weight(.semibold))
                                Text(link.kind.rawValue)
                                    .font(.caption2)
                                    .opacity(0.8)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(link.kind == .sustainable ? Color.ooBlue : Color.ooBrown.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }
                }
            }
        }
        .foregroundColor(.ooBrown)
        .padding()
        .background(Color.ooButter)
        .cornerRadius(20)
    }
}

// MARK: - Closet helpers used by several screens
struct ClosetContext {
    let items: [WardrobeItem]
    let logs: [WearLog]

    var lookup: [UUID: WardrobeItem] {
        Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
    var snapshots: [ItemSnapshot] { items.map(\.snapshot) }

    /// Item sets worn in the last 7 days (so the engine avoids repeats)
    var recentSets: [Set<UUID>] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return logs.filter { $0.date >= weekAgo }.map { Set($0.itemIDs) }
    }

    func suggest(trend: TrendLook? = nil, weather: WeatherSnapshot? = nil, count: Int = 5) async -> [Outfit] {
        await OutfitEngine.shared.suggestOutfits(
            from: snapshots,
            trend: trend,
            weather: weather,
            recentlyWorn: recentSets,
            preferences: .current,   // favorite colors + the user's own style note
            count: count
        )
    }

    /// Marks every piece as worn + saves a WearLog
    static func logWear(_ outfit: Outfit, trendID: String? = nil, lookup: [UUID: WardrobeItem], in context: ModelContext) {
        for id in outfit.itemIDs { lookup[id]?.markWorn() }
        context.insert(WearLog(itemIDs: outfit.itemIDs, trendID: trendID))
        try? context.save()
    }
}
