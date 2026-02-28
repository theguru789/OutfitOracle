//
//  ContentView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/9/26.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // MARK: Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.brown)
                    
                    Text("Feeling lucky?")
                        .foregroundColor(.brown.opacity(0.7))
                    
                    Spacer()
                    
                    Image(systemName: "mic.fill")
                        .foregroundColor(.brown)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.brown, lineWidth: 2)
                )
                .padding(.horizontal)
                
                
                // MARK: Top Row
                HStack(spacing: 15) {
                    
                    // Weather Card
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 90)
                        .overlay(
                            HStack {
                                Image(systemName: "cloud.sun.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.yellow)
                                
                                VStack(alignment: .leading) {
                                    Text("H: 45°")
                                    Text("L: 39°")
                                }
                                .foregroundColor(.brown)
                            }
                        )
                    
                    // Oracle Look
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.pink.opacity(0.3))
                        .frame(height: 90)
                        .overlay(
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(.white)
                                
                                Text("Oracle’s Look\nof the Week")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .bold()
                            }
                        )
                }
                .padding(.horizontal)
                
                
//                // MARK: Sale Banner
//                RoundedRectangle(cornerRadius: 25)
//                    .fill(Color.brown.opacity(0.6))
//                    .frame(height: 120)
//                    .overlay(
//                        HStack {
//                            Text("20% OFF")
//                                .font(.largeTitle)
//                                .bold()
//                                .foregroundColor(.yellow)
//                            
//                            Spacer()
//                            
//                            VStack(alignment: .leading) {
//                                Text("Shop Now!")
//                                    .font(.title)
//                                Text("all apparel")
//                            }
//                            .foregroundColor(.white)
//                            
//                            Image(systemName: "arrow.right")
//                                .foregroundColor(.yellow)
//                        }
//                        .padding()
//                    )
//                    .padding(.horizontal)
                
                
                // MARK: Middle Section
                HStack() {
                    
                    // One Year Ago Card
                    VStack {
                        Text("One year ago today")
                            .foregroundColor(.white)
                            .bold()
                        
                        Image("outfit_sample") // add your asset image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .padding()
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(25)
                    
                    
                    VStack(spacing: 15) {
                        
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.yellow.opacity(0.4))
                            .frame(height: 120)
                            .overlay(
                                Text("What should I\nwear today?")
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.pink.opacity(0.4))
                                    .bold()
                            )
                        
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 80)
                            .overlay(
                                Text("See my weekly stats")
                                    .foregroundColor(.brown)
                            )
                    }
                }
                .padding(.horizontal)
                
                
                // MARK: Explore Banner
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.pink.opacity(0.4))
                    .frame(height: 70)
                    .overlay(
                        HStack {
                            Text("Explore new arrivals")
                                .font(.headline)
                                .foregroundColor(.white)
                                .bold()
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    )
                    .padding(.horizontal)
                
                
                Spacer()
            }
        }
    }
}
