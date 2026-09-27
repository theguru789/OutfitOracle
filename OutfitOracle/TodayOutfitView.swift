//
//  TodayOutfitView.swift
//  OutfitOracle
//
//  "What should I wear today?" — outfits from your own closet, ranked by the
//  on-device OutfitScorer and adjusted for today's weather.
//

import SwiftData
import SwiftUI

struct TodayOutfitView: View {
    /// true = "Feeling lucky?": show one surprise pick instead of the ranked list
    var lucky = false

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived }) private var items: [WardrobeItem]
    @Query(sort: \WearLog.date, order: .reverse) private var logs: [WearLog]

    @State private var outfits: [Outfit] = []
    @State private var selection = 0
    @State private var isLoading = true
    @State private var loggedID: UUID?

    var body: some View {
        let context = ClosetContext(items: items, logs: logs)
        let lookup = context.lookup

        NavigationStack {
            ZStack {
                Color.ooCream.ignoresSafeArea()

                VStack(spacing: 16) {
                    if let weather = appState.weather {
                        HStack {
                            Image(systemName: weather.symbol)
                                .foregroundColor(.yellow)
                            Text("H: \(WeatherService.format(weather.highC))  L: \(WeatherService.format(weather.lowC))")
                            Spacer()
                            if weather.isCold { Text("Layer up").font(.caption.bold()) }
                        }
                        .foregroundColor(.ooBrown)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                    }

                    if isLoading {
                        Spacer()
                        ProgressView("Consulting the Oracle…").tint(.brown)
                        Spacer()
                    } else if outfits.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        TabView(selection: $selection) {
                            ForEach(Array(outfits.enumerated()), id: \.element.id) { index, outfit in
                                ScrollView {
                                    OutfitCard(outfit: outfit, lookup: lookup,
                                               background: index.isMultiple(of: 2) ? .ooButter : Color.ooPink.opacity(0.6))
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .indexViewStyle(.page(backgroundDisplayMode: .always))

                        if outfits.indices.contains(selection) {
                            let outfit = outfits[selection]
                            Button(loggedID == outfit.id ? "Logged — enjoy your day!" : "Wear this") {
                                ClosetContext.logWear(outfit, lookup: lookup, in: modelContext)
                                loggedID = outfit.id
                            }
                            .buttonStyle(OOButtonStyle())
                            .disabled(loggedID == outfit.id)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(lucky ? "Feeling lucky" : "Today's picks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await load(context) }
                    } label: {
                        Image(systemName: "shuffle")
                    }
                    .accessibilityLabel("Shuffle")
                }
            }
            .task { await load(context) }
        }
        .tint(.brown)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tshirt")
                .font(.system(size: 48))
            Text("Add at least a top and a bottom (or a dress) to get outfit ideas.")
                .multilineTextAlignment(.center)
            Button("Add clothes") {
                dismiss()
                appState.selectedTab = .camera
            }
            .buttonStyle(OOButtonStyle())
        }
        .foregroundColor(.ooBrown)
        .padding()
    }

    private func load(_ context: ClosetContext) async {
        isLoading = true
        await appState.loadWeather()
        var result = await context.suggest(weather: appState.weather, count: lucky ? 10 : 5)
        if lucky, let surprise = result.randomElement() {
            result = [surprise]
        }
        outfits = result
        selection = 0
        loggedID = nil
        isLoading = false
    }
}
