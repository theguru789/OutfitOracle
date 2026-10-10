//
//  MainTabView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/25/26.
//

import SwiftData
import SwiftUI

struct MainTabView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @AppStorage(PrefKeys.hasOnboarded) private var hasOnboarded = false

    /// Show the intro on first launch
    private var needsOnboarding: Bool { !hasOnboarded }

    init() {
        // iOS 17–18: classic solid brown bar. (On iOS 26+ the bar is Liquid Glass;
        // the solid strip added by `solidTabBarBackdrop()` keeps it from being see-through.)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.ooBrown)
        let normal = UIColor(Color.ooLightText).withAlphaComponent(0.75)
        let selected = UIColor(Color.ooGold)
        for layout in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            layout.normal.iconColor = normal
            layout.normal.titleTextAttributes = [.foregroundColor: normal]
            layout.selected.iconColor = selected
            layout.selected.titleTextAttributes = [.foregroundColor: selected]
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    /// Gold reads well on the solid brown bar (iOS 17–18); on the lighter
    /// Liquid Glass bar (iOS 26+) espresso brown is easier to see.
    private static var selectedTabColor: Color {
        if #available(iOS 26.0, *) { return .ooBrown }
        return .ooGold
    }

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            UploadView()
                .solidTabBarBackdrop()
                .tabItem { Label("Camera", systemImage: "camera") }
                .tag(AppTab.camera)

            ChatView()
                .solidTabBarBackdrop()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
                .tag(AppTab.chat)

            ContentView()
                .solidTabBarBackdrop()
                .tabItem { Label("Oracle", systemImage: "sparkles") }
                .tag(AppTab.home) // Home tab

            ClosetView()
                .solidTabBarBackdrop()
                .tabItem { Label("Closet", systemImage: "hanger") }
                .tag(AppTab.closet)

            ProfileView()
                .solidTabBarBackdrop()
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(AppTab.profile)
        }
        .tint(Self.selectedTabColor)
        .fullScreenCover(isPresented: Binding(
            get: { needsOnboarding },
            set: { if !$0 { hasOnboarded = true } }
        )) {
            OnboardingView {
                hasOnboarded = true
                // Debug builds: load the test closet once the intro is done
                OutfitOracleApp.loadTestClosetForDevelopment(into: modelContext)
            }
        }
    }
}

extension View {
    /// Fills the area behind the tab bar with solid brown. On iOS 26+ the Liquid
    /// Glass bar floats over the page; with nothing scrolling underneath it, the
    /// glass keeps its shape and shine but isn't see-through.
    func solidTabBarBackdrop() -> some View {
        overlay(alignment: .bottom) {
            // A zero-height view whose background stretches down through the
            // bottom safe area = exactly the tab bar's area
            Color.clear
                .frame(height: 0)
                .background(Color.ooBrown.ignoresSafeArea(.container, edges: .bottom))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
