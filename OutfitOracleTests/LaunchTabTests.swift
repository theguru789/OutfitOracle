//
//  LaunchTabTests.swift
//  OutfitOracleTests
//
//  First launch ever → Camera; every launch after → Home.
//

import Foundation
import Testing
@testable import OutfitOracle

struct LaunchTabTests {

    /// Throwaway settings store so tests never touch the real app's defaults
    private func freshDefaults() -> UserDefaults {
        let name = "LaunchTabTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func firstLaunchOpensCameraThenHome() {
        let defaults = freshDefaults()
        #expect(AppState.launchTab(isDemo: false, defaults: defaults) == .camera)
        #expect(AppState.launchTab(isDemo: false, defaults: defaults) == .home)
        #expect(AppState.launchTab(isDemo: false, defaults: defaults) == .home)
    }

    @Test func peopleWhoAlreadyFinishedTheIntroGoHome() {
        let defaults = freshDefaults()
        defaults.set(true, forKey: PrefKeys.hasOnboarded)
        #expect(AppState.launchTab(isDemo: false, defaults: defaults) == .home)
    }

    @Test func demoRunsAlwaysOpenHome() {
        let defaults = freshDefaults()
        #expect(AppState.launchTab(isDemo: true, defaults: defaults) == .home)
        // and don't use up the real first launch
        #expect(AppState.launchTab(isDemo: false, defaults: defaults) == .camera)
    }
}
