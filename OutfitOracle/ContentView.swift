//
//  ContentView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/9/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {

    @Environment(AppState.self) private var appState
    @Environment(TrendService.self) private var trends
    @AppStorage(PrefKeys.highContrast) private var highContrast = false
    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived }) private var items: [WardrobeItem]
    @Query(sort: \WearLog.date, order: .reverse) private var logs: [WearLog]

    @State private var showToday = false
    @State private var showLucky = false
    @State private var showStats = false
    @State private var path = NavigationPath()
    @State private var todayPick: Outfit?
    @State private var selectedItem: WardrobeItem?

    enum HomeRoute: Hashable {
        case trends
        case trend(TrendLook)
    }

    /// Outfit logged about a year ago (±3 days), for the memory card
    private var yearAgoItem: WardrobeItem? {
        let calendar = Calendar.current
        guard let target = calendar.date(byAdding: .year, value: -1, to: Date()) else { return nil }
        let lookup = ClosetContext(items: items, logs: logs).lookup
        return logs
            .filter { abs($0.date.timeIntervalSince(target)) < 3 * 86_400 }
            .compactMap { $0.itemIDs.lazy.compactMap { lookup[$0] }.first }
            .first
    }

    var body: some View {
        let lookup = ClosetContext(items: items, logs: logs).lookup

        NavigationStack(path: $path) {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: Search Bar → surprise outfit
                        Button {
                            showLucky = true
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.ooBrown)

                                Text("Feeling lucky?")
                                    .foregroundColor(.ooBrown.opacity(0.7))

                                Spacer()

                                Image(systemName: "dice.fill")
                                    .foregroundColor(.ooBrown)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.ooBrown, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal)


                        // MARK: Top Row
                        HStack(spacing: 15) {

                            // Weather Card
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.2))
                                .frame(minHeight: 90)
                                .overlay(
                                    HStack {
                                        Image(systemName: appState.weather?.symbol ?? "cloud.sun.fill")
                                            .font(.largeTitle)
                                            .foregroundColor(.yellow)

                                        VStack(alignment: .leading) {
                                            if let weather = appState.weather {
                                                Text("H: \(WeatherService.format(weather.highC))")
                                                Text("L: \(WeatherService.format(weather.lowC))")
                                            } else {
                                                Text(appState.weatherStatus)
                                                    .font(.caption)
                                            }
                                        }
                                        .foregroundColor(.ooBrown)
                                    }
                                    .padding(.horizontal, 8)
                                )

                            // Oracle Look
                            Button {
                                if let featured = trends.featured { path.append(HomeRoute.trend(featured)) }
                            } label: {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.ooPink)
                                    .frame(minHeight: 90)
                                    .overlay(
                                        HStack {
                                            Image(systemName: "lightbulb")
                                                .foregroundColor(highContrast ? .ooBrown : .white)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Oracle’s Look\nof the Week")
                                                    .fontWeight(.semibold)
                                                    .bold()
                                                if let featured = trends.featured {
                                                    Text(featured.name)
                                                        .font(.caption)
                                                }
                                            }
                                            .foregroundColor(highContrast ? .ooBrown : .white)
                                            .minimumScaleFactor(0.7)
                                        }
                                        .padding(.horizontal, 8)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)


                        // MARK: Middle Section
                        HStack(alignment: .top) {

                            // One Year Ago Card
                            VStack {
                                Text("One year ago today")
                                    .foregroundColor(.white)
                                    .bold()
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.8)

                                Group {
                                    if let item = yearAgoItem, let image = item.croppedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Image("outfit_sample")
                                            .resizable()
                                            .scaledToFill()
                                            .overlay(alignment: .bottom) {
                                                Text("Log outfits to see memories")
                                                    .font(.caption2.bold())
                                                    .foregroundColor(.white)
                                                    .padding(4)
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color.black.opacity(0.35))
                                            }
                                    }
                                }
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                            .padding()
                            .background(Color.ooBlue)
                            .cornerRadius(25)


                            VStack(spacing: 15) {

                                Button {
                                    showToday = true
                                } label: {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.ooButter)
                                        .frame(height: 120)
                                        .overlay(
                                            Text("What should I\nwear today?")
                                                .font(.title3)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(.ooBrown)
                                                .bold()
                                                .minimumScaleFactor(0.7)
                                                .padding(6)
                                        )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    showStats = true
                                } label: {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 80)
                                        .overlay(
                                            Text("See my weekly stats")
                                                .foregroundColor(.ooBrown)
                                                .multilineTextAlignment(.center)
                                                .padding(6)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)


                        // MARK: Explore Banner
                        Button {
                            path.append(HomeRoute.trends)
                        } label: {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.ooPink)
                                .frame(height: 56)
                                .overlay(
                                    HStack {
                                        Text("Explore trends")
                                            .font(.headline)
                                            .foregroundColor(highContrast ? .ooBrown : .white)
                                            .bold()

                                        Spacer()

                                        Image(systemName: "arrow.right")
                                            .foregroundColor(highContrast ? .ooBrown : .white)
                                    }
                                    .padding(.horizontal)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        // MARK: Today's pick — a ready outfit right on the home screen
                        if let pick = todayPick {
                            Button {
                                showToday = true
                            } label: {
                                HStack(spacing: 12) {
                                    OutfitFlatLay(outfit: pick, lookup: lookup, height: 150)
                                        .frame(width: 150)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Today's pick")
                                            .font(.headline)
                                        Text("\(pick.percent)% style match")
                                            .font(.subheadline)
                                        if let reason = pick.reasons.dropFirst().first {
                                            Text(reason)
                                                .font(.caption)
                                                .lineLimit(3)
                                        }
                                        Spacer(minLength: 0)
                                        Label("More outfits", systemImage: "arrow.right")
                                            .font(.caption.bold())
                                    }
                                    Spacer(minLength: 0)
                                }
                                .foregroundColor(.ooBrown)
                                .padding(12)
                                .background(Color.ooButter)
                                .cornerRadius(25)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }

                        // MARK: Not worn lately — nudge forgotten pieces back into rotation
                        let forgotten = items.filter(\.isForgotten)
                            .sorted { $0.daysSinceWorn > $1.daysSinceWorn }
                            .prefix(10)
                        if !forgotten.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Not worn lately")
                                    .font(.headline)
                                    .foregroundColor(.ooBrown)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Array(forgotten)) { item in
                                            Button {
                                                selectedItem = item
                                            } label: {
                                                ItemThumbnail(item: item, height: 80)
                                                    .frame(width: 76)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                Group {
                    switch route {
                    case .trends: TrendsView()
                    case .trend(let look): TrendDetailView(look: look)
                    }
                }
                .toolbar(.visible, for: .navigationBar)
            }
        }
        .tint(.ooBrown)
        .task { await appState.loadWeather() }
        .sheet(isPresented: $showToday) { TodayOutfitView() }
        .sheet(isPresented: $showLucky) { TodayOutfitView(lucky: true) }
        .sheet(isPresented: $showStats) { StatsView() }
        .sheet(item: $selectedItem) { ItemDetailView(item: $0) }
        .task(id: items.count) {
            await appState.loadWeather()
            todayPick = await ClosetContext(items: items, logs: logs)
                .suggest(weather: appState.weather, count: 1).first
        }
    }
}
