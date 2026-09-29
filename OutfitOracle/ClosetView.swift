//
//  ClosetView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/28/26.
//

import SwiftData
import SwiftUI

struct ClosetView: View {

    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived },
           sort: \WardrobeItem.dateAdded, order: .reverse)
    private var items: [WardrobeItem]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    @State private var selectedCategory: ClosetFilter = .all
    @State private var selectedItem: WardrobeItem?

    private var filtered: [WardrobeItem] {
        items.filter { selectedCategory.includes($0.role) }
    }

    var body: some View {
        ZStack {
            // Background
            Color.ooCream
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                OOHeader(title: "My Closet") {
                    Text("\(items.count) items")
                        .font(.subheadline)
                        .foregroundColor(.ooLightText.opacity(0.9))
                }

                // Category Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ClosetFilter.allCases) { category in
                            OOChip(title: category.title, selected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding()
                }

                // Clothing Grid
                if items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filtered) { item in
                                Button {
                                    selectedItem = item
                                } label: {
                                    ClosetItemCard(item: item)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint(item.isForgotten ? "Not worn lately. Opens details." : "Opens details.")
                            }
                        }
                        .padding()
                        .padding(.bottom, 70)
                    }
                }
            }

            // Add Button (floating)
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    Button {
                        appState.selectedTab = .camera
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.ooLightText)
                            .frame(width: 60, height: 60)
                            .background(Color.brown)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .accessibilityLabel("Add clothes")
                    .padding()
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "hanger")
                .font(.system(size: 56))
                .foregroundColor(.ooBrown)
            Text("Your closet is empty")
                .font(.title3.bold())
                .foregroundColor(.ooBrown)
            Text("Snap your clothes and the Oracle will sort them for you.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.ooBrown.opacity(0.8))
                .padding(.horizontal, 40)
            Button("Snap your closet") { appState.selectedTab = .camera }
                .buttonStyle(OOButtonStyle())
                .padding(.horizontal, 60)
            Spacer()
        }
    }

    struct ClosetItemCard: View {
        let item: WardrobeItem

        var body: some View {
            VStack(spacing: 6) {
                ItemThumbnail(item: item, height: 130)
                    .overlay(alignment: .topTrailing) {
                        if item.isForgotten {
                            Image(systemName: "moon.zzz.fill")
                                .font(.caption)
                                .padding(6)
                                .background(Color.ooPink)
                                .clipShape(Circle())
                                .padding(6)
                                .foregroundColor(.white)
                                .accessibilityLabel("Not worn lately")
                        }
                    }

                HStack(spacing: 6) {
                    ColorSwatch(hex: item.colorHex, size: 12)
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundColor(Color.brown)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .background(Color.ooButter)
            .cornerRadius(20)
        }
    }
}

enum ClosetFilter: String, CaseIterable, Identifiable {
    case all, tops, bottoms, dresses, outerwear, shoesAccessories

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .tops: "Tops"
        case .bottoms: "Bottoms"
        case .dresses: "Dresses"
        case .outerwear: "Outerwear"
        case .shoesAccessories: "Shoes & Accessories"
        }
    }

    func includes(_ role: GarmentRole) -> Bool {
        switch self {
        case .all: true
        case .tops: role == .top
        case .bottoms: role == .bottom
        case .dresses: role == .dress
        case .outerwear: role == .outerwear
        case .shoesAccessories: role == .shoes || role == .accessory
        }
    }
}
