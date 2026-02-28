//
//  ProfileView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/28/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.94, green: 0.92, blue: 0.87)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Top Header
                VStack(spacing: 20) {
                    Spacer().frame(height: 20)
                    
                    // Profile Image Placeholder
                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 180, height: 180)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80)
                                .foregroundColor(Color(red: 0.94, green: 0.92, blue: 0.87))
                        )
                    
                    // Name
                    Text("Full Name")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Color(red: 0.98, green: 0.95, blue: 0.90))
                    
                    Spacer().frame(height: 20)
                }
                .frame(maxWidth: .infinity)
                .background(Color.brown)
                
                // Grid buttons
                VStack(spacing: 30) {
                    Spacer().frame(height: 30)
                    
                    HStack(spacing: 30) {
                        ProfileCard(icon: "chart.bar.fill", title: "Stats")
                        ProfileCard(icon: "gearshape.fill", title: "Settings")
                    }
                    
                    HStack(spacing: 30) {
                        ProfileCard(icon: "slider.horizontal.3", title: "Accessibility")
                        ProfileCard(icon: "archivebox.fill", title: "Archives")
                    }
                    
                    Spacer()
                }
            }
        }
    }
    struct ProfileCard: View {
        let icon: String
        let title: String
        
        var body: some View {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(Color.brown)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.brown)
            }
            .frame(width: 150, height: 120)
            .background(Color(red: 0.95, green: 0.90, blue: 0.55))
            .cornerRadius(25)
        }
    }
}
