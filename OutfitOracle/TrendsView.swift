//
//  TrendsView.swift
//  OutfitOracle
//
//  Current trend looks, how much of each you already own, and what's missing.
//

import SwiftData
import SwiftUI

struct TrendsView: View {
    @Environment(TrendService.self) private var trends
    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived }) private var items: [WardrobeItem]

    var body: some View {
        let closet = items.map(\.snapshot)
        ZStack {
            Color.ooCream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(trends.feed.season)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.ooBrown.opacity(0.8))
                    Text("Wear the trend with what you already own. Only buy the missing piece, and buy it secondhand first.")
                        .font(.subheadline)
                        .foregroundColor(.ooBrown)

                    ForEach(Array(trends.looks.enumerated()), id: \.element.id) { index, look in
                        let coverage = TrendMatcher.coverage(of: look, closet: closet)
                        NavigationLink(value: look) {
                            TrendCard(coverage: coverage,
                                      background: index.isMultiple(of: 2) ? Color.ooPink : Color.ooBlue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Trends")
        .navigationDestination(for: TrendLook.self) { look in
            TrendDetailView(look: look)
        }
    }
}

struct TrendCard: View {
    let coverage: TrendCoverage
    var background: Color = .ooPink
    @AppStorage(PrefKeys.highContrast) private var highContrast = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(coverage.look.name)
                    .font(.title3.bold())
                Spacer()
                Image(systemName: "arrow.right")
            }
            HStack(spacing: 6) {
                ForEach(coverage.look.palette, id: \.self) { ColorSwatch(hex: $0, size: 22) }
            }
            Text(coverage.look.blurb)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            ProgressView(value: coverage.fraction)
                .tint(.yellow)
            Text(coverage.summary)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(highContrast ? .ooBrown : .white)
        .padding()
        .background(background)
        .cornerRadius(25)
    }
}

struct TrendDetailView: View {
    let look: TrendLook

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived }) private var items: [WardrobeItem]
    @Query(sort: \WearLog.date, order: .reverse) private var logs: [WearLog]

    @State private var outfits: [Outfit] = []
    @State private var isBuilding = false
    @State private var safariURL: URL?
    @State private var loggedID: UUID?

    var body: some View {
        let context = ClosetContext(items: items, logs: logs)
        let coverage = TrendMatcher.coverage(of: look, closet: context.snapshots)
        let lookup = context.lookup

        ZStack {
            Color.ooCream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TrendCard(coverage: coverage)

                    // Pieces you already own
                    if !coverage.matches.isEmpty {
                        sectionTitle("Already in your closet")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(coverage.matches.map { $0.item }) { snap in
                                    if let item = lookup[snap.id] {
                                        VStack(spacing: 4) {
                                            ItemThumbnail(item: item, height: 110)
                                                .frame(width: 100)
                                            Text(item.name).font(.caption).lineLimit(1)
                                        }
                                        .frame(width: 110)
                                        .ooCard()
                                    }
                                }
                            }
                        }
                    }

                    // Remix from closet
                    Button {
                        Task { await build(context) }
                    } label: {
                        if isBuilding {
                            ProgressView().tint(.white)
                        } else {
                            Text("Build it from my closet")
                        }
                    }
                    .buttonStyle(OOButtonStyle())
                    .disabled(items.isEmpty || isBuilding)

                    ForEach(outfits) { outfit in
                        VStack(spacing: 8) {
                            OutfitCard(outfit: outfit, lookup: lookup)
                            Button(loggedID == outfit.id ? "Logged!" : "Wear this") {
                                ClosetContext.logWear(outfit, trendID: look.id, lookup: lookup, in: modelContext)
                                loggedID = outfit.id
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.ooBrown)
                            .disabled(loggedID == outfit.id)
                            .sensoryFeedback(.success, trigger: loggedID)

                            ShareOutfitButton(outfit: outfit, lookup: lookup, trendName: look.name)
                        }
                    }

                    // What's missing: secondhand + sustainable first
                    if !coverage.missing.isEmpty {
                        sectionTitle("Complete the look")
                        Text(ShopService.tagline)
                            .font(.caption)
                            .foregroundColor(.ooBrown.opacity(0.8))
                        ForEach(coverage.missing) { slot in
                            ShopLinksView(slot: slot) { safariURL = $0 }
                        }
                    } else {
                        Label("You already own this whole look. No shopping needed!", systemImage: "leaf.fill")
                            .font(.headline)
                            .foregroundColor(.ooBrown)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.ooButter)
                            .cornerRadius(20)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(look.name)
        .navigationBarTitleDisplayMode(.inline)
        .safariSheet(url: $safariURL)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.ooBrown)
    }

    private func build(_ context: ClosetContext) async {
        isBuilding = true
        outfits = await context.suggest(trend: look, weather: appState.weather, count: 3)
        isBuilding = false
    }
}
