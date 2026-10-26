//
//  OnboardingView.swift
//  OutfitOracle
//
//  First-launch intro, kept short: mission, a quick animated "how it works",
//  about you (name + male/female), the style quiz (required), privacy.
//

import SwiftData
import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage(PrefKeys.name) private var name = ""
    @AppStorage(PrefKeys.gender) private var genderRaw = Gender.unspecified.rawValue
    @AppStorage(PrefKeys.styleQuiz) private var quizData = Data()
    @State private var page = 0
    @State private var showGuide = false
    @State private var showQuiz = false

    private let stylePage = 3

    private let pageCount = 5

    var body: some View {
        ZStack {
            Color.ooCream.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcome.tag(0)
                    howItWorks.tag(1)
                    aboutYou.tag(2)
                    yourStyle.tag(3)
                    privacy.tag(4)
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

                if page == stylePage && quizData.isEmpty {
                    Button("Take the style quiz") { showQuiz = true }
                        .buttonStyle(OOButtonStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 44)   // same height as Next + Skip, so the page doesn't jump
                } else if page < pageCount - 1 {
                    Button("Next") { withAnimation { page += 1 } }
                        .buttonStyle(OOButtonStyle())
                        .padding(.horizontal)
                    // Skip the intro, but not the style quiz
                    Button("Skip") {
                        if quizData.isEmpty { withAnimation { page = stylePage } } else { onFinish() }
                    }
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
                        onFinish()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.ooBrown)
                    .padding(.vertical, 10)
                }
            }
            .padding(.bottom, 8)
        }
        .onChange(of: page) { _, newPage in
            // The quiz is required: no swiping past it until it's done
            if newPage > stylePage && quizData.isEmpty { withAnimation { page = stylePage } }
        }
        .sheet(isPresented: $showGuide) { HowItWorksGuideView() }
        .fullScreenCover(isPresented: $showQuiz) {
            StyleQuizView(canClose: false) {
                showQuiz = false
                withAnimation { page = stylePage + 1 }
            }
        }
    }

    // MARK: - Pages (one or two short lines each)

    /// Scrolls only if it truly has to (big text / small phones) and flashes the
    /// scroll bar so nothing is ever silently hidden below the dots.
    private func pageContainer<Content: View>(alignment: HorizontalAlignment = .leading,
                                             @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: alignment, spacing: 14) {
                content()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicatorsFlash(onAppear: true)
        .scrollDismissesKeyboard(.interactively)
    }

    private var welcome: some View {
        pageContainer(alignment: .center) {
            Spacer(minLength: 24)
            Image("OracleLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260, maxHeight: 143)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibilityLabel("Outfit Oracle logo")

            Text("Love what you already own.")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.ooBrown)

            Label("92 million tons of clothes are thrown away every year.", systemImage: "leaf.fill")
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .foregroundColor(.ooDeepBrown)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.ooButter)
                .cornerRadius(18)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var howItWorks: some View {
        pageContainer {
            pageTitle("How it works")
            AppSimulationView(height: 270)
            Button {
                showGuide = true
            } label: {
                Label("See how it works in detail", systemImage: "book")
                    .font(.subheadline.bold())
                    .foregroundColor(.ooBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.ooButter)
                    .cornerRadius(16)
            }
        }
    }

    private var aboutYou: some View {
        pageContainer {
            pageTitle("About you")

            TextField("Your first name", text: $name)
                .textFieldStyle(.roundedBorder)
                .textContentType(.givenName)
                .submitLabel(.done)   // Return closes the keyboard

            Text("I am…").font(.headline).foregroundColor(.ooBrown)
            VStack(spacing: 10) {
                ForEach(Gender.allCases) { gender in
                    let isOn = genderRaw == gender.rawValue
                    Button {
                        genderRaw = gender.rawValue
                    } label: {
                        HStack {
                            Text(gender.label)
                            Spacer()
                            if isOn { Image(systemName: "checkmark.circle.fill") }
                        }
                        .font(.body.weight(.semibold))
                        .padding()
                        .background(isOn ? Color.ooBrown : Color.ooButter)
                        .foregroundColor(isOn ? .ooLightText : .ooBrown)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            Text("Used to show the right section in shop links.")
                .font(.caption)
                .foregroundColor(.ooBrown.opacity(0.8))
        }
    }

    private var yourStyle: some View {
        pageContainer {
            pageTitle("Your style")
            Text("6 quick questions so the Oracle picks outfits that feel like you.")
                .font(.headline)
                .foregroundColor(.ooBrown)
                .fixedSize(horizontal: false, vertical: true)

            if quizData.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    infoRow("tshirt", "Your vibe and colors")
                    infoRow("hand.thumbsdown", "What you'd never wear")
                    infoRow("clock", "About a minute. Skip any question you like.")
                }
            } else {
                StyleQuizCard { showQuiz = true }
            }
        }
    }

    private var privacy: some View {
        pageContainer {
            pageTitle("Private by design")
            infoRow("iphone", "Your closet stays on your phone.")
            infoRow("cpu", "The AI runs on-device.")
            infoRow("location", "Location is only used for weather.")
        }
    }

    // MARK: - Pieces

    private func pageTitle(_ text: String) -> some View {
        Text(text)
            .font(.largeTitle.bold())
            .foregroundColor(.ooBrown)
            .minimumScaleFactor(0.8)
            .lineLimit(1)
    }

    private func infoRow(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.headline)
            .foregroundColor(.ooBrown)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ooButter)
            .cornerRadius(18)
    }
}
