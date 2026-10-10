//
//  StatsView.swift
//  OutfitOracle
//
//  Weekly stats focused on re-wearing what you own.
//

import SwiftData
import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived }) private var items: [WardrobeItem]
    @Query(sort: \WearLog.date, order: .reverse) private var logs: [WearLog]
    @Query(filter: #Predicate<WardrobeItem> { $0.isArchived }) private var passedOn: [WardrobeItem]
    @Environment(TrendService.self) private var trends

    @State private var selectedItem: WardrobeItem?

    /// Trend pieces the user already owned — each one is a purchase they didn't need
    private var trendPiecesOwned: Int {
        let closet = items.map(\.snapshot)
        return trends.looks.reduce(0) { $0 + TrendMatcher.coverage(of: $1, closet: closet).matches.count }
    }

    private var trendOutfitsWorn: Int {
        logs.filter { $0.trendID != nil }.count
    }

    private var weekLogs: [WearLog] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return logs.filter { $0.date >= weekAgo }
    }

    private var wornLast30: Double {
        guard !items.isEmpty else { return 0 }
        let worn = items.filter { $0.lastWorn != nil && $0.daysSinceWorn < 30 }.count
        return Double(worn) / Double(items.count)
    }

    private var totalRewears: Int {
        items.reduce(0) { $0 + max(0, $1.wearCount - 1) }
    }

    private var forgotten: [WardrobeItem] {
        items.filter(\.isForgotten).sorted { $0.daysSinceWorn > $1.daysSinceWorn }
    }

    private var mostWorn: [WardrobeItem] {
        Array(items.filter { $0.wearCount > 0 }.sorted { $0.wearCount > $1.wearCount }.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ooCream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        impactSection

                        HStack(spacing: 12) {
                            tile(value: "\(weekLogs.count)", label: "outfits logged this week", color: .ooButter)
                            tile(value: "\(totalRewears)", label: "total re-wears", color: Color.ooPink)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Closet worn in the last 30 days")
                                .font(.headline)
                            ProgressView(value: wornLast30)
                                .tint(.ooBrown)
                            Text("\(Int(wornLast30 * 100))% of your \(items.count) pieces")
                                .font(.caption)
                        }
                        .foregroundColor(.ooBrown)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)

                        if !forgotten.isEmpty {
                            itemRow(title: "Forgotten gems. Give these another wear!", items: forgotten, color: .ooBlue)
                        }
                        if !mostWorn.isEmpty {
                            itemRow(title: "Your most-loved pieces", items: mostWorn, color: .ooButter)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedItem) { ItemDetailView(item: $0) }
        }
        .tint(.ooBrown)
    }

    // MARK: - Sustainability impact (only numbers the app can actually measure)
    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your sustainability impact", systemImage: "leaf.fill")
                .font(.headline)

            HStack(spacing: 10) {
                impactStat("\(trendPiecesOwned)", "trend pieces you already owned, so no need to buy them")
                impactStat("\(trendOutfitsWorn)", "trend looks worn from your own closet")
                impactStat("\(passedOn.count)", "pieces passed on or retired")
            }

            Text("Keeping clothes in use just 9 months longer cuts their carbon, water and waste footprint by about 20–30%.")
                .font(.caption)
            Text("Source: WRAP, Valuing Our Clothes (2012)")
                .font(.caption2)
                .opacity(0.8)
        }
        .foregroundColor(.ooBrown)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ooButter)
        .cornerRadius(20)
    }

    private func impactStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title.bold())
            Text(label)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(8)
        .background(Color.ooCream)
        .cornerRadius(14)
        .accessibilityElement(children: .combine)
    }

    private func tile(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.largeTitle.bold())
            Text(label).font(.caption).multilineTextAlignment(.center)
        }
        .foregroundColor(.ooBrown)
        .frame(maxWidth: .infinity)
        .padding()
        .background(color)
        .cornerRadius(20)
    }

    private func itemRow(title: String, items: [WardrobeItem], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            VStack(spacing: 4) {
                                ItemThumbnail(item: item, height: 90)
                                Text(item.lastWorn == nil ? "Never worn" : "\(item.daysSinceWorn)d ago")
                                    .font(.caption2)
                            }
                            .frame(width: 90)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .foregroundColor(.ooBrown)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color)
        .cornerRadius(20)
    }
}
