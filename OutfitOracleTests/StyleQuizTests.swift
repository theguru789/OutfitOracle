//
//  StyleQuizTests.swift
//  OutfitOracleTests
//
//  The style quiz: picking answers, and what the answers mean for outfit scores.
//

import Foundation
import Testing
@testable import OutfitOracle

struct StyleQuizTests {
    private func question(_ id: String) -> StyleQuiz.Question { StyleQuiz.question(id)! }
    private func option(_ id: String, in questionID: String) -> StyleQuiz.Option {
        question(questionID).options.first { $0.id == id }!
    }

    @Test func singleChoiceReplacesThePick() {
        let feel = question("feel")
        let picks = StyleQuiz.toggle(option("sharp", in: "feel"), in: feel, picks: ["comfy"])
        #expect(picks == ["sharp"])
    }

    @Test func tappingAgainUnpicks() {
        let vibe = question("vibe")
        #expect(StyleQuiz.toggle(option("Casual", in: "vibe"), in: vibe, picks: ["Casual"]).isEmpty)
    }

    @Test func vibeKeepsAtMostTwoPicks() {
        let vibe = question("vibe")
        let picks = StyleQuiz.toggle(option("Sporty", in: "vibe"), in: vibe, picks: ["Casual", "Minimal"])
        #expect(picks == ["Minimal", "Sporty"])   // oldest pick swapped out
    }

    @Test func imOpenClearsTheOtherPicks() {
        let never = question("never")
        #expect(StyleQuiz.toggle(option("open", in: "never"), in: never, picks: ["leather", "florals"]) == ["open"])
        #expect(StyleQuiz.toggle(option("leather", in: "never"), in: never, picks: ["open"]) == ["leather"])
    }

    @Test func answersBecomeLikesAndDislikes() {
        let prefs = StyleQuiz.preferences(from: ["colors": ["earthy"], "never": ["leather", "dresses"]])
        #expect(prefs.likedColors == ["brown", "green", "orange"])
        #expect(prefs.dislikedFabrics == ["leather"])
        #expect(prefs.dislikedRoles == [.dress])
    }

    @Test func dislikesWinOverLikes() {
        // "Tough & rugged" likes leather, but "never wear leather" should win
        let prefs = StyleQuiz.preferences(from: ["feel": ["rugged"], "never": ["leather"]])
        #expect(!prefs.likedFabrics.contains("leather"))
        #expect(prefs.likedFabrics.contains("denim"))
        #expect(prefs.dislikedFabrics.contains("leather"))
    }

    @Test func styleNameAndSummary() {
        let answers: StyleQuiz.Answers = ["vibe": ["Casual", "Minimal"], "never": ["leather"]]
        #expect(StyleQuiz.styleName(for: answers) == "Casual & Minimal")
        #expect(StyleQuiz.summary(for: answers) == "vibe: Casual, Minimal; never wear: Leather")
        #expect(StyleQuiz.styleName(for: [:]) == nil)
    }

    @Test func everyAnswerUsesTheAppsVocabulary() {
        for option in StyleQuiz.questions.flatMap(\.options) {
            #expect((option.likedColors.union(option.dislikedColors).union(option.swatches))
                .isSubset(of: Set(Vocabulary.colors)), "\(option.id)")
            #expect(option.likedPatterns.union(option.dislikedPatterns).isSubset(of: Set(Vocabulary.patterns)), "\(option.id)")
            #expect(option.likedFabrics.union(option.dislikedFabrics).isSubset(of: Set(Vocabulary.fabrics)), "\(option.id)")
        }
    }
}
