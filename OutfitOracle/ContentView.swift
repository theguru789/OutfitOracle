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
                                    .foregroundColor(.brown)

                                Text("Feeling lucky?")
                                    .foregroundColor(.brown.opacity(0.7))

                                Spacer()

                                Image(systemName: "dice.fill")
                                    .foregroundColor(.brown)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.brown, lineWidth: 2)
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
                                        .foregroundColor(.brown)
                                    }
                                    .padding(.horizontal, 8)
                                )

                            // Oracle Look
                            Button {
                                if let featured = trends.featured { path.append(HomeRoute.trend(featured)) }
                            } label: {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.pink.opacity(0.3))
                                    .frame(minHeight: 90)
                                    .overlay(
                                        HStack {
                                            Image(systemName: "lightbulb")
                                                .foregroundColor(highContrast ? .brown : .white)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Oracle’s Look\nof the Week")
                                                    .fontWeight(.semibold)
                                                    .bold()
                                                if let featured = trends.featured {
                                                    Text(featured.name)
                                                        .font(.caption)
                                                }
                                            }
                                            .foregroundColor(highContrast ? .brown : .white)
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
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(25)


                            VStack(spacing: 15) {

                                Button {
                                    showToday = true
                                } label: {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.yellow.opacity(0.4))
                                        .frame(height: 120)
                                        .overlay(
                                            Text("What should I\nwear today?")
                                                .font(.title3)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(.brown)
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
                                                .foregroundColor(.brown)
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
                                .fill(Color.pink.opacity(0.4))
                                .frame(height: 70)
                                .overlay(
                                    HStack {
                                        Text("Explore trends")
                                            .font(.headline)
                                            .foregroundColor(highContrast ? .brown : .white)
                                            .bold()

                                        Spacer()

                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
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
        .tint(.brown)
        .task { await appState.loadWeather() }
        .sheet(isPresented: $showToday) { TodayOutfitView() }
        .sheet(isPresented: $showLucky) { TodayOutfitView(lucky: true) }
        .sheet(isPresented: $showStats) { StatsView() }
    }
}
