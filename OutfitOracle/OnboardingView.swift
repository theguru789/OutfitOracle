//
//  OnboardingView.swift
//  OutfitOracle
//
//  First-launch intro: the mission, how the app works, a quick style quiz
//  (from the original proposal), and how your data stays on your phone.
//

import SwiftData
import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(PrefKeys.name) private var name = ""
    @AppStorage(PrefKeys.favoriteColors) private var favoriteColorsRaw = ""
    @AppStorage(PrefKeys.styles) private var stylesRaw = ""
    @State private var page = 0

    private let pageCount = 4

    var body: some View {
        ZStack {
            Color.ooCream.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcome.tag(0)
                    howItWorks.tag(1)
                    styleQuiz.tag(2)
                    privacy.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots + next button
                HStack(spacing: 8) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.ooBrown : Color.ooBrown.opacity(0.25))
                            .frame(width: i == page ? 22 : 8, height: 8)
                    }
                }
                .animation(.easeInOut, value: page)
                .padding(.bottom, 12)
                .accessibilityHidden(true)

                if page < pageCount - 1 {
                    Button("Next") { withAnimation { page += 1 } }
                        .buttonStyle(OOButtonStyle())
                        .padding(.horizontal)
                    Button("Skip") { onFinish() }
                        .font(.subheadline)
                        .foregroundColor(.ooBrown)
                        .padding(.vertical, 10)
                } else {
                    Button("Snap my closet") {
                        appState.selectedTab = .camera
                        onFinish()
                    }
                    .buttonStyle(OOButtonStyle())
                    .padding(.horizontal)
                    Button("Try it with a sample closet") {
                        SampleData.load(into: modelContext)
                        appState.selectedTab = .home
                        onFinish()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.ooBrown)
                    .padding(.vertical, 10)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Pages

    private var welcome: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("Outfit_Oracle")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .accessibilityLabel("Outfit Oracle logo")
                    .padding(.top, 40)

                Text("Smarter wardrobes.\nSustainable choices.\nConfident you.")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.ooBrown)

                VStack(spacing: 6) {
                    Text("92 million tons")
                        .font(.largeTitle.bold())
                        .foregroundColor(.ooBrown)
                    Text("of textile waste are produced every year. Most of it starts with clothes we buy and barely wear.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.ooBrown.opacity(0.85))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.ooButter)
                .cornerRadius(25)

                Text("Outfit Oracle helps you love what you already own.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.ooBrown)
            }
            .padding(.horizontal, 24)
        }
    }

    private var howItWorks: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("How it works")
                    .font(.largeTitle.bold())
                    .foregroundColor(.ooBrown)
                    .padding(.top, 40)

                step(1, "camera.viewfinder", "Snap your clothes",
                     "On-device AI finds each piece and reads its type, color, pattern and fabric.", .ooBlue)
                step(2, "sparkles", "Remix what you own",
                     "Get outfits for today's weather, plus a nudge to re-wear pieces you've forgotten.", Color.ooPink)
                step(3, "leaf", "Wear the trends, waste less",
                     "See how much of each trend you already own. If one piece is missing, shop secondhand first.", .ooButter)
            }
            .padding(.horizontal, 24)
        }
    }

    private var styleQuiz: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your style")
                    .font(.largeTitle.bold())
                    .foregroundColor(.ooBrown)
                    .padding(.top, 40)
                Text("A quick quiz so the Oracle can personalize your outfits. You can change this later in Settings.")
                    .font(.subheadline)
                    .foregroundColor(.ooBrown.opacity(0.85))

                TextField("Your first name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.givenName)

                Text("Colors you love").font(.headline).foregroundColor(.ooBrown)
                FlowChips(options: Vocabulary.colors, selected: setBinding($favoriteColorsRaw)) { color in
                    HStack(spacing: 4) {
                        ColorSwatch(hex: Vocabulary.hex(for: color), size: 12)
                        Text(color.capitalizedFirst)
                    }
                }

                Text("Styles that feel like you").font(.headline).foregroundColor(.ooBrown)
                FlowChips(options: SettingsView.styleOptions, selected: setBinding($stylesRaw)) { Text($0) }
            }
            .padding(.horizontal, 24)
        }
    }

    private var privacy: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Private by design")
                    .font(.largeTitle.bold())
                    .foregroundColor(.ooBrown)
                    .padding(.top, 40)

                privacyRow("iphone", "Your closet stays on your phone",
                           "Photos and outfits are saved only on this device. There's no account and no cloud upload.")
                privacyRow("cpu", "The AI runs on-device",
                           "Clothing detection, outfit scoring and chat all happen on your iPhone.")
                privacyRow("location", "Only approximate location, only for weather",
                           "Used to check today's temperature. You can say no, and everything else still works.")
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Pieces

    private func step(_ number: Int, _ symbol: String, _ title: String, _ text: String, _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: 48, height: 48)
                .background(color)
                .clipShape(Circle())
                .foregroundColor(.ooBrown)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(number). \(title)").font(.headline)
                Text(text).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(.ooBrown)
        }
        .accessibilityElement(children: .combine)
    }

    private func privacyRow(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 32)
                .foregroundColor(.ooBrown)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(.ooBrown)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ooButter)
        .cornerRadius(20)
        .accessibilityElement(children: .combine)
    }

    private func setBinding(_ raw: Binding<String>) -> Binding<Set<String>> {
        Binding(
            get: { Set(raw.wrappedValue.split(separator: ",").map(String.init)) },
            set: { raw.wrappedValue = $0.sorted().joined(separator: ",") }
        )
    }
}
