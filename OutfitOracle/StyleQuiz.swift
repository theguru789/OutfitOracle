//
//  StyleQuiz.swift
//  OutfitOracle
//
//  A short "what's your style?" quiz. Shown in the intro (skippable) and from
//  Profile any time after. Each answer turns into likes / dislikes that the
//  Oracle uses when it scores outfits and chats.
//

import SwiftUI

// MARK: - Questions + what each answer means
nonisolated enum StyleQuiz {

    struct Option: Identifiable, Hashable, Sendable {
        let id: String
        let title: String
        var symbol: String? = nil
        var swatches: [String] = []          // app color names shown as dots
        var exclusive = false                 // "Nothing, I'm open" clears the others
        var likedColors: Set<String> = []
        var dislikedColors: Set<String> = []
        var likedPatterns: Set<String> = []
        var dislikedPatterns: Set<String> = []
        var likedFabrics: Set<String> = []
        var dislikedFabrics: Set<String> = []
        var dislikedRoles: Set<GarmentRole> = []
    }

    struct Question: Identifiable, Sendable {
        let id: String
        let title: String
        let hint: String
        let maxPicks: Int                     // 1 = single choice
        let options: [Option]
    }

    static let questions: [Question] = [
        Question(id: "vibe", title: "What's your everyday vibe?", hint: "Pick up to 2", maxPicks: 2, options: [
            Option(id: "Casual", title: "Casual", symbol: "tshirt", likedFabrics: ["cotton", "denim"]),
            Option(id: "Streetwear", title: "Streetwear", symbol: "headphones",
                   likedPatterns: ["graphic"], likedFabrics: ["denim"]),
            Option(id: "Preppy", title: "Preppy", symbol: "graduationcap",
                   likedPatterns: ["striped", "plaid"], likedFabrics: ["cotton", "wool"]),
            Option(id: "Minimal", title: "Minimal", symbol: "circle",
                   likedColors: ["black", "white", "grey"], likedPatterns: ["solid"]),
            Option(id: "Sporty", title: "Sporty", symbol: "figure.run", likedFabrics: ["knit", "cotton"]),
            Option(id: "Formal", title: "Sharp", symbol: "briefcase",
                   likedColors: ["navy", "black"], likedPatterns: ["solid"], likedFabrics: ["wool"]),
            Option(id: "Boho", title: "Boho", symbol: "leaf",
                   likedPatterns: ["floral", "print", "embroidered"], likedFabrics: ["lace", "chiffon"]),
        ]),
        Question(id: "colors", title: "Which colors do you reach for?", hint: "Pick any", maxPicks: 6, options: [
            Option(id: "neutrals", title: "Neutrals", swatches: ["black", "white", "grey"],
                   likedColors: ["black", "white", "grey"]),
            Option(id: "earthy", title: "Earthy", swatches: ["brown", "green", "orange"],
                   likedColors: ["brown", "green", "orange"]),
            Option(id: "dark", title: "Dark & moody", swatches: ["navy", "black", "purple"],
                   likedColors: ["navy", "black"]),
            Option(id: "blues", title: "Blues", swatches: ["blue", "navy", "white"],
                   likedColors: ["blue", "navy"]),
            Option(id: "brights", title: "Brights", swatches: ["red", "yellow", "orange"],
                   likedColors: ["red", "yellow", "orange"]),
            Option(id: "soft", title: "Soft & pastel", swatches: ["pink", "purple", "white"],
                   likedColors: ["pink", "purple"]),
        ]),
        Question(id: "patterns", title: "Patterns?", hint: "Pick any", maxPicks: 4, options: [
            Option(id: "plain", title: "Keep it plain", symbol: "square.fill", likedPatterns: ["solid"]),
            Option(id: "stripes", title: "Stripes & plaid", symbol: "line.3.horizontal",
                   likedPatterns: ["striped", "plaid", "checkered"]),
            Option(id: "graphics", title: "Graphics & prints", symbol: "star.square",
                   likedPatterns: ["graphic", "print"]),
            Option(id: "florals", title: "Florals", symbol: "camera.macro", likedPatterns: ["floral"]),
        ]),
        Question(id: "feel", title: "How should clothes feel?", hint: "Pick one", maxPicks: 1, options: [
            Option(id: "comfy", title: "Soft & comfy", symbol: "cloud", likedFabrics: ["knit", "cotton"]),
            Option(id: "sharp", title: "Sharp & put-together", symbol: "sparkles", likedFabrics: ["wool", "cotton"]),
            Option(id: "rugged", title: "Tough & rugged", symbol: "mountain.2", likedFabrics: ["denim", "leather"]),
            Option(id: "light", title: "Light & flowy", symbol: "wind", likedFabrics: ["silk", "chiffon", "satin"]),
        ]),
        Question(id: "never", title: "Anything you'd never wear?", hint: "Pick any", maxPicks: 6, options: [
            Option(id: "open", title: "Nothing, I'm open", symbol: "hand.thumbsup", exclusive: true),
            Option(id: "leather", title: "Leather", symbol: "xmark.circle", dislikedFabrics: ["leather"]),
            Option(id: "florals", title: "Florals", symbol: "xmark.circle", dislikedPatterns: ["floral"]),
            Option(id: "loud", title: "Loud graphics", symbol: "xmark.circle", dislikedPatterns: ["graphic", "print"]),
            Option(id: "brights", title: "Bright colors", symbol: "xmark.circle",
                   dislikedColors: ["red", "yellow", "orange", "pink"]),
            Option(id: "dresses", title: "Dresses & skirts", symbol: "xmark.circle", dislikedRoles: [.dress]),
        ]),
        Question(id: "occasion", title: "Where do you wear outfits most?", hint: "Pick one", maxPicks: 1, options: [
            Option(id: "school", title: "School", symbol: "backpack", likedFabrics: ["cotton", "denim"]),
            Option(id: "work", title: "Work", symbol: "building.2", likedFabrics: ["wool"]),
            Option(id: "out", title: "Going out", symbol: "music.note", likedFabrics: ["denim", "leather"]),
            Option(id: "active", title: "On the move", symbol: "bicycle", likedFabrics: ["knit", "cotton"]),
        ]),
    ]

    /// Picks the user made, keyed by question id (kept in UserDefaults as JSON)
    typealias Answers = [String: [String]]

    static var saved: Answers {
        get {
            guard let data = UserDefaults.standard.data(forKey: PrefKeys.styleQuiz),
                  let answers = try? JSONDecoder().decode(Answers.self, from: data) else { return [:] }
            return answers
        }
        set {
            UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: PrefKeys.styleQuiz)
        }
    }

    static var isTaken: Bool { !saved.isEmpty }

    static func options(for answers: Answers) -> [Option] {
        questions.flatMap { question in
            question.options.filter { (answers[question.id] ?? []).contains($0.id) }
        }
    }

    /// Everything the answers add up to. Dislikes win over likes.
    static func preferences(from answers: Answers) -> StylePreferences {
        var prefs = StylePreferences()
        for option in options(for: answers) {
            prefs.merge(StylePreferences(
                likedColors: option.likedColors, dislikedColors: option.dislikedColors,
                likedPatterns: option.likedPatterns, dislikedPatterns: option.dislikedPatterns,
                likedFabrics: option.likedFabrics, dislikedFabrics: option.dislikedFabrics,
                dislikedRoles: option.dislikedRoles
            ))
        }
        return prefs
    }

    /// "Casual & Minimal", or nil before the quiz is taken
    static func styleName(for answers: Answers) -> String? {
        let vibes = question("vibe")?.options.filter { (answers["vibe"] ?? []).contains($0.id) }.map(\.title) ?? []
        return vibes.isEmpty ? nil : vibes.joined(separator: " & ")
    }

    /// One plain sentence for the chat model, e.g.
    /// "vibe: Casual, Minimal; colors: Earthy; never wear: Leather"
    static func summary(for answers: Answers) -> String {
        let labels = ["vibe": "vibe", "colors": "colors", "patterns": "patterns",
                      "feel": "clothes should feel", "never": "never wear", "occasion": "mostly dresses for"]
        return questions.compactMap { question in
            let picks = question.options.filter { (answers[question.id] ?? []).contains($0.id) }.map(\.title)
            guard !picks.isEmpty else { return nil }
            return "\(labels[question.id] ?? question.id): \(picks.joined(separator: ", "))"
        }
        .joined(separator: "; ")
    }

    static func question(_ id: String) -> Question? { questions.first { $0.id == id } }

    /// Applies a tap on `option` to the current picks for `question`
    static func toggle(_ option: Option, in question: Question, picks: [String]) -> [String] {
        var picks = picks
        if let index = picks.firstIndex(of: option.id) {
            picks.remove(at: index)
            return picks
        }
        if question.maxPicks == 1 || option.exclusive { return [option.id] }
        let exclusiveIDs = Set(question.options.filter(\.exclusive).map(\.id))
        picks.removeAll { exclusiveIDs.contains($0) }
        if picks.count >= question.maxPicks { picks.removeFirst() }   // swap out the oldest pick
        picks.append(option.id)
        return picks
    }
}

// MARK: - Quiz screen
struct StyleQuizView: View {
    /// false in the intro (the quiz is required); true for a retake from Profile
    var canClose = true
    /// Called when the quiz closes (finished or "Later")
    var onClose: () -> Void

    @AppStorage(PrefKeys.styles) private var stylesRaw = ""
    @AppStorage(PrefKeys.styleNotes) private var styleNotes = ""
    @State private var answers: StyleQuiz.Answers = StyleQuiz.saved
    @State private var step = 0
    @State private var goingForward = true

    private let questions = StyleQuiz.questions
    private var wordsStep: Int { questions.count }
    private var resultStep: Int { questions.count + 1 }

    var body: some View {
        ZStack {
            Color.ooCream.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Group {
                    if step < questions.count {
                        questionPage(questions[step])
                    } else if step == wordsStep {
                        wordsPage
                    } else {
                        resultPage
                    }
                }
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: goingForward ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: goingForward ? .leading : .trailing).combined(with: .opacity)
                ))
                .frame(maxHeight: .infinity, alignment: .top)

                bottomButtons
            }
        }
        .sensoryFeedback(.selection, trigger: answers)
    }

    // MARK: Bars

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                if step > 0 && step < resultStep {
                    Button {
                        move(to: step - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .padding(8)
                    }
                    .accessibilityLabel("Back")
                }
                Spacer()
                if canClose && step < resultStep {
                    Button("Later") { onClose() }
                        .font(.subheadline.weight(.semibold))
                        .padding(8)
                        .accessibilityHint("Close without changing your style.")
                }
            }
            .foregroundColor(.ooBrown)
            .frame(minHeight: 40)

            if step < resultStep {
                // Progress: one segment per step (questions + "in your own words")
                HStack(spacing: 4) {
                    ForEach(0...wordsStep, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Color.ooBrown : Color.ooBrown.opacity(0.2))
                            .frame(height: 6)
                    }
                }
                .animation(.easeInOut, value: step)
                .accessibilityElement()
                .accessibilityLabel("Question \(step + 1) of \(wordsStep + 1)")
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var bottomButtons: some View {
        VStack(spacing: 0) {
            if step < questions.count {
                let picked = !(answers[questions[step].id] ?? []).isEmpty
                Button(picked ? "Next" : "Skip question") { move(to: step + 1) }
                    .buttonStyle(OOButtonStyle())
            } else if step == wordsStep {
                Button("See my style") {
                    save()
                    move(to: resultStep)
                }
                .buttonStyle(OOButtonStyle())
            } else {
                Button("Done") { onClose() }
                    .buttonStyle(OOButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    // MARK: Pages

    private func questionPage(_ question: StyleQuiz.Question) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(question.title)
                    .font(.title.bold())
                    .foregroundColor(.ooBrown)
                    .fixedSize(horizontal: false, vertical: true)
                Text(question.hint)
                    .font(.subheadline)
                    .foregroundColor(.ooBrown.opacity(0.8))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                          spacing: 12) {
                    ForEach(question.options) { option in
                        optionCard(option, in: question)
                    }
                }
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func optionCard(_ option: StyleQuiz.Option, in question: StyleQuiz.Question) -> some View {
        let picks = answers[question.id] ?? []
        let isOn = picks.contains(option.id)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                answers[question.id] = StyleQuiz.toggle(option, in: question, picks: picks)
            }
        } label: {
            VStack(spacing: 10) {
                if !option.swatches.isEmpty {
                    HStack(spacing: -6) {
                        ForEach(option.swatches, id: \.self) { ColorSwatch(hex: Vocabulary.hex(for: $0), size: 30) }
                    }
                    .padding(4)
                    .background(Color.ooCream.opacity(isOn ? 1 : 0), in: Capsule())   // dark dots stay visible on brown
                } else if let symbol = option.symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 28))
                }
                Text(option.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .padding(8)
            .background(isOn ? Color.ooBrown : Color.ooButter)
            .foregroundColor(isOn ? .ooLightText : .ooBrown)
            .cornerRadius(20)
            .overlay(alignment: .topTrailing) {
                if isOn {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.ooGold)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var wordsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Anything else?")
                    .font(.title.bold())
                    .foregroundColor(.ooBrown)
                Text("Say it in your own words (optional).")
                    .font(.subheadline)
                    .foregroundColor(.ooBrown.opacity(0.8))
                TextField("e.g. comfy, earthy colors, no leather", text: $styleNotes, axis: .vertical)
                    .lineLimit(2...5)
                    .padding(12)
                    .background(Color.ooButter)
                    .cornerRadius(16)
                    .foregroundColor(.ooBrown)
                    .submitLabel(.done)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var resultPage: some View {
        let prefs = StyleQuiz.preferences(from: answers)
        let loves = Array(prefs.likedColors).sorted()
        let skips = (prefs.dislikedColors.sorted() + prefs.dislikedPatterns.sorted() + prefs.dislikedFabrics.sorted()
                     + prefs.dislikedRoles.map(\.rawValue).sorted())
        return ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundColor(.ooGold)
                    .padding(.top, 24)
                Text("Your style")
                    .font(.headline)
                    .foregroundColor(.ooBrown.opacity(0.8))
                Text(StyleQuiz.styleName(for: answers) ?? "All yours")
                    .font(.largeTitle.bold())
                    .foregroundColor(.ooBrown)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)

                VStack(alignment: .leading, spacing: 12) {
                    if !loves.isEmpty {
                        Text("Colors you love").font(.subheadline.bold())
                        HStack(spacing: 6) {
                            ForEach(loves, id: \.self) { ColorSwatch(hex: Vocabulary.hex(for: $0), size: 24) }
                        }
                        .accessibilityElement()
                        .accessibilityLabel(loves.joined(separator: ", "))
                    }
                    if !skips.isEmpty {
                        Text("The Oracle will skip").font(.subheadline.bold())
                        Text(skips.map(\.capitalizedFirst).joined(separator: ", "))
                            .font(.subheadline)
                    }
                    Label("Your outfit picks now lean this way.", systemImage: "wand.and.stars")
                        .font(.subheadline)
                }
                .foregroundColor(.ooBrown)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.ooButter)
                .cornerRadius(20)
            }
            .padding()
        }
    }

    // MARK: Actions

    private func move(to newStep: Int) {
        goingForward = newStep > step
        withAnimation(.easeInOut(duration: 0.25)) { step = newStep }
    }

    private func save() {
        let picked = answers.filter { !$0.value.isEmpty }
        // Remember they took it even if every question was skipped
        StyleQuiz.saved = picked.isEmpty ? ["done": []] : picked
        // Vibe answers double as the Settings style chips
        if let vibes = picked["vibe"] {
            stylesRaw = vibes.sorted().joined(separator: ",")
        }
    }
}

// MARK: - "Take the quiz" / "Your style" card (Profile)
struct StyleQuizCard: View {
    var action: () -> Void
    @AppStorage(PrefKeys.styleQuiz) private var quizData = Data()   // redraws when the quiz is saved

    var body: some View {
        let answers = (try? JSONDecoder().decode(StyleQuiz.Answers.self, from: quizData)) ?? [:]
        let taken = !answers.isEmpty
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: taken ? "sparkles" : "questionmark.bubble.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(taken ? "Your style: \(StyleQuiz.styleName(for: answers) ?? "All yours")" : "Take the style quiz")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(taken ? "Tap to retake" : "6 quick questions so outfits feel like you")
                        .font(.caption)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.ooBrown)
            .padding()
            .frame(maxWidth: .infinity)
            .background(taken ? Color.ooButter : Color.ooPink)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
