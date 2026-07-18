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

    let container: ModelContainer = {
        let schema = Schema([WardrobeItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
