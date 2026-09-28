//
//  OutfitOracleApp.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/9/26.
//

import SwiftUI
import SwiftData

@main
struct OutfitOracleApp: App {

    @State private var appState = AppState()
    @State private var trends = TrendService.shared

    /// Launch with `-demoCloset` for UI tests / demo recordings: an in-memory store
    /// pre-filled with the sample closet (the real closet is left untouched).
    static let isDemo = ProcessInfo.processInfo.arguments.contains("-demoCloset")

    let container: ModelContainer = {
        let schema = Schema([WardrobeItem.self, WearLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: OutfitOracleApp.isDemo)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
                .environment(trends)
                .task {
                    if Self.isDemo { SampleData.load(into: container.mainContext) }
                    await trends.refresh()
                }
        }
        .modelContainer(container)
    }
}
