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

    @State private var selectedItem: WardrobeItem?

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
                        HStack(spacing: 12) {
                            tile(value: "\(weekLogs.count)", label: "outfits logged this week", color: .ooButter)
                            tile(value: "\(totalRewears)", label: "total re-wears", color: Color.ooPink)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Closet worn in the last 30 days")
                                .font(.headline)
                            ProgressView(value: wornLast30)
                                .tint(.brown)
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
        .tint(.brown)
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
