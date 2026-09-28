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
        vc.preferredControlTintColor = .brown
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

// MARK: - Outfit card: thumbnails of each piece + score + reasons
struct OutfitCard: View {
    let outfit: Outfit
    let lookup: [UUID: WardrobeItem]
    var background: Color = .ooButter

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(outfit.items) { snap in
                    if let item = lookup[snap.id] {
                        VStack(spacing: 4) {
                            ItemThumbnail(item: item, height: 90)
                            Text(item.role.singular.capitalizedFirst)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                }
            }

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
            favoriteColors: UserDefaults.standard.favoriteColors,
            recentlyWorn: recentSets,
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
