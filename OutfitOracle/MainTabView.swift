//
//  MainTabView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/25/26.
//

import SwiftUI

struct MainTabView: View {

    @Environment(AppState.self) private var appState
    @AppStorage(PrefKeys.hasOnboarded) private var hasOnboarded = false

    /// Show the intro on first launch, or when replayed from Profile ▸ How it works
    private var needsOnboarding: Bool { !hasOnboarded }

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.brown

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {

            UploadView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Camera")
                }
                .tag(AppTab.camera)

            ChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Chat")
                }
                .tag(AppTab.chat)

            ContentView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Oracle")
                }
                .tag(AppTab.home) // Home tab

            ClosetView()
                .tabItem {
                    Image(systemName: "hanger")
                    Text("Closet")
                }
                .tag(AppTab.closet)

            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(AppTab.profile)
        }
        .accentColor(.yellow)
        .background(Color.brown.ignoresSafeArea(edges: .bottom))
        .fullScreenCover(isPresented: Binding(
            get: { needsOnboarding },
            set: { if !$0 { hasOnboarded = true } }
        )) {
            OnboardingView { hasOnboarded = true }
        }
    }
}
