//
//  ClosetView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/28/26.
//

import SwiftUI

struct ClosetView: View {
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @State private var selectedCategory = "All"
    let categories = ["All", "Tops", "Bottoms", "Shoes", "Accessories"]
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.94, green: 0.92, blue: 0.87)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Header
                Text("My Closet")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color(red: 0.98, green: 0.95, blue: 0.90))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brown)
                
                // Category Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedCategory == category ?
                                        Color.brown :
                                        Color(red: 0.95, green: 0.90, blue: 0.55)
                                    )
                                    .foregroundColor(
                                        selectedCategory == category ?
                                        Color(red: 0.98, green: 0.95, blue: 0.90) :
                                        Color.brown
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
                
                // Clothing Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        
                        ForEach(0..<10) { _ in
                            ClosetItemCard()
                        }
                    }
                    .padding()
                }
            }
            
            // Add Button (floating)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button {
                        // Add new item action later
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(Color(red: 0.98, green: 0.95, blue: 0.90))
                            .frame(width: 60, height: 60)
                            .background(Color.brown)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        }
    }
    struct ClosetItemCard: View {
        var body: some View {
            VStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 120)
                    .cornerRadius(15)
                    .overlay(
                        Image(systemName: "tshirt")
                            .font(.system(size: 40))
                            .foregroundColor(Color.brown)
                    )
                
                Text("Item Name")
                    .font(.subheadline)
                    .foregroundColor(Color.brown)
            }
            .padding(10)
            .background(Color(red: 0.95, green: 0.90, blue: 0.55))
            .cornerRadius(20)
        }
    }
}
