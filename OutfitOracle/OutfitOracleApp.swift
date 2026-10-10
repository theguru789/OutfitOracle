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
        let schema = Schema([WardrobeItem.self, WearLog.self, SavedOutfit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: OutfitOracleApp.isDemo)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    init() {
        // Demo/test runs skip the intro, unless `-showOnboarding` asks for it fresh
        if Self.isDemo {
            let show = ProcessInfo.processInfo.arguments.contains("-showOnboarding")
            UserDefaults.standard.set(!show, forKey: PrefKeys.hasOnboarded)
        }
    }

    /// Builds run from Xcode (Debug) get the sample closet once, so there's
    /// something to try on a real iPhone right away (after the intro).
    /// App Store (Release) builds
    /// start with an empty closet. Never re-adds items after you delete them.
    @MainActor
    static func loadTestClosetForDevelopment(into context: ModelContext) {
        #if DEBUG
        guard !isDemo, UserDefaults.standard.bool(forKey: PrefKeys.hasOnboarded) else { return }
        let key = "debugSampleClosetLoaded.v3"   // v3 = real photos, men's clothing only
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        // Replace the older icon-based test clothes (if an earlier build added them)
        let oldSampleNames: Set<String> = ["Navy striped shirt", "Grey chunky knit", "Cream knit sweater",
                                           "Black leather jacket", "Brown leather boots", "Grey knit scarf",
                                           // women's pieces from the v2 test closet
                                           "Blush hoodie", "Black trousers", "Floral midi dress", "Sage slip dress",
                                           "Peach slip dress", "Dark floral dress", "Mint blazer", "Black ankle boots",
                                           "Tan heeled boots", "Brown slingback flats"]
        if let existing = try? context.fetch(FetchDescriptor<WardrobeItem>()) {
            // Old test items only: names unique to the old set, or a current sample name
            // still using the old icon/crop (new samples always come with a cutout photo)
            for item in existing where oldSampleNames.contains(item.name)
                || (SampleData.allNames.contains(item.name) && item.cutoutImageData == nil) {
                context.delete(item)
            }
            try? context.save()
        }
        SampleData.load(into: context)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
                .environment(trends)
                .task {
                    if Self.isDemo {
                        SampleData.load(into: container.mainContext)
                    } else {
                        Self.loadTestClosetForDevelopment(into: container.mainContext)
                    }
                    await trends.refresh()
                    await CutoutService.backfill(container.mainContext)
                }
        }
        .modelContainer(container)
    }
}
