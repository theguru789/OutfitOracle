//
//  ChatView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/28/26.
//

import SwiftUI

struct ChatView: View {
    @State private var messageText = ""
    
    var body: some View {
        ZStack {
            // Background color (light beige like your design)
            Color(red: 0.94, green: 0.92, blue: 0.87)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Top Header
                HStack {
                    Text("See what’s new")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0.98, green: 0.95, blue: 0.90))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.98, green: 0.95, blue: 0.90))
                }
                .padding()
                .background(Color.brown)
                
                // Messages area
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Left (Oracle)
                        ChatBubble(text: "New seasonal trends are here!", isUser: false)
                        
                        ChatBubble(text: "Try mixing neutrals with statement pieces.", isUser: false)
                        
                        // Right (User)
                        ChatBubble(text: "Show me outfit ideas", isUser: true)
                        
                        ChatBubble(text: "What works for winter?", isUser: true)
                    }
                    .padding()
                }
                
                // Input bar
                HStack {
                    TextField("Ask the Oracle...", text: $messageText)
                        .padding(12)
                    
                    Button {
                        // send action later
                        messageText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.brown)
                            .clipShape(Circle())
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(red: 0.97, green: 0.95, blue: 0.70))
                )
                .padding()
            }
        }
    }
    struct ChatBubble: View {
        let text: String
        let isUser: Bool
        
        var body: some View {
            HStack {
                if isUser { Spacer() }
                
                Text(text)
                    .padding()
                    .foregroundColor(.black)
                    .background(isUser ? Color.blue.opacity(0.6) : Color.pink.opacity(0.4))
                    .cornerRadius(20)
                    .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)
                
                if !isUser { Spacer() }
            }
        }
    }
}
