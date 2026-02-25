//
//  MainTabView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/25/26.
//

import SwiftUI

struct MainTabView: View {
    
    // Step 1: Track the selected tab
    @State private var selectedTab = 2 // 0 = Camera, 1 = Chat, 2 = Home/Oracle, 3 = Closet, 4 = Profile
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.brown
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        // Step 2: Bind the selection
        TabView(selection: $selectedTab) {
            
            UploadView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Camera")
                }
                .tag(0)
            
            Text("Chat Screen")
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Chat")
                }
                .tag(1)
            
            ContentView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Oracle")
                }
                .tag(2) // Home tab
            
            Text("Closet Screen")
                .tabItem {
                    Image(systemName: "hanger")
                    Text("Closet")
                }
                .tag(3)
            
            Text("Profile Screen")
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.yellow)
        .background(Color.brown.ignoresSafeArea(edges: .bottom))
    }
}
