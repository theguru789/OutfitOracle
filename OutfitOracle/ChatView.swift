//
//  ChatView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/28/26.
//

import SwiftData
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var outfits: [Outfit] = []
}

struct ChatView: View {
    @Environment(AppState.self) private var appState
    @Environment(TrendService.self) private var trends
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived }) private var items: [WardrobeItem]
    @Query(sort: \WearLog.date, order: .reverse) private var logs: [WearLog]

    @State private var messageText = ""
    @State private var oracle = OracleChat()
    @State private var isThinking = false
    @State private var showTrends = false
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hi! I'm the Oracle. Ask me what to wear, what's trending, or what you've forgotten about.", isUser: false)
    ]

    private let suggestions = ["What should I wear today?", "What's trending?", "What have I forgotten about?", "What should I buy?"]

    var body: some View {
        let lookup = ClosetContext(items: items, logs: logs).lookup

        ZStack {
            // Background color (light beige like your design)
            Color.ooCream
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Top Header
                Button {
                    showTrends = true
                } label: {
                    OOHeader(title: "See what’s new") {
                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundColor(.ooLightText)
                    }
                }
                .buttonStyle(.plain)

                if oracle.mode == .basic {
                    Text("Basic Oracle mode: on-device AI needs an Apple Intelligence iPhone")
                        .font(.caption2)
                        .foregroundColor(.ooBrown.opacity(0.7))
                        .padding(.top, 6)
                }

                // Messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(messages) { message in
                                VStack(spacing: 10) {
                                    ChatBubble(text: message.text, isUser: message.isUser)
                                    ForEach(message.outfits) { outfit in
                                        OutfitCard(outfit: outfit, lookup: lookup)
                                            .padding(.trailing, 40)
                                    }
                                }
                                .id(message.id)
                            }
                            if isThinking {
                                ChatBubble(text: "…", isUser: false)
                                    .id("thinking")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation { proxy.scrollTo(messages.last?.id, anchor: .top) }
                    }
                }

                // Quick prompts
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            OOChip(title: suggestion, selected: false) {
                                send(suggestion)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 6)
                .background(Color.ooCream)
                .disabled(isThinking)

                // Input bar
                HStack {
                    TextField("Ask the Oracle...", text: $messageText)
                        .padding(12)
                        .submitLabel(.send)
                        .onSubmit { send(messageText) }

                    Button {
                        send(messageText)
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.brown)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Send")
                    .disabled(isThinking || messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.trailing, 4)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.ooChatInput)
                )
                .padding()
            }
        }
        .sheet(isPresented: $showTrends) {
            NavigationStack {
                TrendsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showTrends = false }
                        }
                    }
            }
            .tint(.brown)
        }
    }

    private func send(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        messages.append(ChatMessage(text: text, isUser: true))
        messageText = ""
        isThinking = true

        let closet = ClosetContext(items: items, logs: logs)
        let context = OracleContext(
            closet: closet.snapshots,
            looks: trends.looks,
            weather: appState.weather,
            favoriteColors: UserDefaults.standard.favoriteColors,
            recentSets: closet.recentSets
        )

        Task {
            await OracleDataStore.shared.update(context)
            let (reply, outfits) = await oracle.reply(to: text)
            messages.append(ChatMessage(text: reply, isUser: false, outfits: outfits))
            isThinking = false
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
                    .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)

                if !isUser { Spacer() }
            }
        }
    }
}
