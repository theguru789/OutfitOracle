//
//  Camera.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/25/26.
//

import SwiftUI

struct UploadView: View {
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 15) {
                
                // MARK: Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Feeling lucky?")
                        .foregroundColor(.brown.opacity(0.7))
                    Spacer()
                    Image(systemName: "mic.fill")
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.brown, lineWidth: 2)
                )
                .padding(.horizontal)
                
                
                // MARK: Outfit Image
                Image("outfit_sample") // add this image in Assets
                    .resizable()
                    .scaledToFill()
                    .frame(height: 450)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .padding(.horizontal)
                
                
                // MARK: Buttons, Upload & retake
                    
                    Button(action: {
                        // Upload action
                    }) {
                        Text("Upload")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        // Retake action
                    }) {
                        Text("Retake")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .padding(.vertical)
        }
    }
}
