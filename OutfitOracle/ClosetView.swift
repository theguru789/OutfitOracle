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

    // 3 compact cards per row (adaptive keeps it readable on small phones)
    let columns = [GridItem(.adaptive(minimum: 104), spacing: 10)]

    @State private var selectedCategory: ClosetFilter = .all
    @State private var selectedItem: WardrobeItem?
    @State private var mode: ClosetMode = .items
    @State private var showOutfitBuilder = false
    @Query private var savedOutfits: [SavedOutfit]

    private var visibleFilters: [ClosetFilter] {
        ClosetFilter.allCases.filter { filter in
            filter == .all || items.contains { filter.includes($0.role) }
        }
    }

    private var filtered: [WardrobeItem] {
        items.filter { selectedCategory.includes($0.role) }
    }

    enum ClosetMode: String, CaseIterable, Identifiable {
        case items = "Items", outfits = "Outfits"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            // Background
            Color.ooCream
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                OOHeader(title: "My Closet") {
                    Text(mode == .items ? "\(items.count) items" : "\(savedOutfits.count) outfits")
                        .font(.subheadline)
                        .foregroundColor(.ooLightText.opacity(0.9))
                }

                // Items | Outfits switch
                HStack(spacing: 0) {
                    ForEach(ClosetMode.allCases) { option in
                        let isOn = mode == option
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { mode = option }
                        } label: {
                            Text(option.rawValue)
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(isOn ? Color.ooBrown : Color.clear)
                                .foregroundColor(isOn ? .ooLightText : .ooBrown)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isOn ? .isSelected : [])
                    }
                }
                .padding(3)
                .background(Color.ooButter)
                .clipShape(Capsule())
                .padding(.horizontal)
                .padding(.top, 8)

                if mode == .items {
                    itemsContent
                } else {
                    ClosetOutfitsList(showBuilder: $showOutfitBuilder)
                }
            }

            // Add Button (floating): add clothes, or build an outfit
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    Button {
                        if mode == .items {
                            appState.selectedTab = .camera
                        } else {
                            showOutfitBuilder = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.ooLightText)
                            .frame(width: 60, height: 60)
                            .background(Color.ooBrown)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .accessibilityLabel(mode == .items ? "Add clothes" : "New outfit")
                    .padding()
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
        }
        .sheet(isPresented: $showOutfitBuilder) { OutfitBuilderView() }
    }

    @ViewBuilder
    private var itemsContent: some View {
        // Category Filters
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Only show filters that have something in them (e.g. no "Dresses" chip without dresses)
                ForEach(visibleFilters) { category in
                    OOChip(title: category.title, selected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }

        // Clothing Grid
        if items.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
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
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
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
            VStack(spacing: 4) {
                ItemThumbnail(item: item, height: 96)
                    .overlay(alignment: .topTrailing) {
                        if item.isForgotten {
                            Image(systemName: "moon.zzz.fill")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.ooPink)
                                .clipShape(Circle())
                                .padding(4)
                                .foregroundColor(.white)
                                .accessibilityLabel("Not worn lately")
                        }
                    }

                HStack(alignment: .top, spacing: 4) {
                    ColorSwatch(hex: item.colorHex, size: 8)
                        .padding(.top, 3)
                    Text(item.name)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(Color.ooBrown)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(6)
            .background(Color.ooButter)
            .cornerRadius(16)
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
