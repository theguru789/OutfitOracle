//
//  PreferencesAndOutfitsTests.swift
//  OutfitOracleTests
//
//  "In your own words" style notes, and the Outfits tab's recommendations.
//

import Foundation
import Testing
@testable import OutfitOracle

struct StylePreferencesTests {

    @Test func likesAndDislikesAreSplit() {
        let prefs = StylePreferences.parse("I love green and denim, no leather, hate florals")
        #expect(prefs.likedColors.contains("green"))
        #expect(prefs.likedFabrics.contains("denim"))
        #expect(prefs.dislikedFabrics == ["leather"])
        #expect(prefs.dislikedPatterns == ["floral"])
        #expect(!prefs.likedFabrics.contains("leather"))
    }

    @Test func everydayWordsMapToAppColors() {
        let prefs = StylePreferences.parse("beige, olive and gray please")
        #expect(prefs.likedColors.isSuperset(of: ["brown", "green", "grey"]))
    }

    @Test func noDressesAvoidsDresses() {
        #expect(StylePreferences.parse("comfy, no dresses").dislikedRoles == [.dress])
    }

    @Test func earthyAndNeutralArePalettes() {
        #expect(StylePreferences.parse("earthy tones").likedColors.isSuperset(of: ["brown", "green"]))
        #expect(StylePreferences.parse("neutral stuff").likedColors.contains("grey"))
    }

    @Test func dislikesLowerTheScore() {
        let prefs = StylePreferences.parse("no leather")
        let leather = [snap(.top), snap(.outerwear, fabric: "leather")]
        let cotton = [snap(.top), snap(.outerwear, fabric: "cotton")]
        #expect(prefs.adjustment(for: leather) < prefs.adjustment(for: cotton))
    }

    @Test func emptyNotesChangeNothing() {
        #expect(StylePreferences.parse("").adjustment(for: [snap(.top), snap(.bottom)]) == 0)
    }
}

struct OutfitRecommendationTests {

    private let engine = OutfitEngine()

    @Test func recommendsSomethingOrPraises() {
        let outfit = [snap(.top, "white", name: "White tee"), snap(.bottom, "blue", fabric: "denim", name: "Jeans")]
        let closet = outfit + [snap(.outerwear, "blue", fabric: "denim", name: "Denim jacket"),
                               snap(.shoes, "white", fabric: "leather", name: "White sneakers"),
                               snap(.top, "red", pattern: "floral", fabric: "chiffon", name: "Red blouse")]
        let advice = engine.recommendation(for: outfit, closet: closet)
        #expect(!advice.text.isEmpty)
        if let change = advice.change {
            // A suggested change is still a wearable outfit made from the closet
            #expect(change.count <= ScorerEncoder.maxItems)
            #expect(change.allSatisfy { piece in closet.contains { $0.id == piece.id } })
            #expect(advice.text.contains("% match"))
        }
    }

    @Test func emptyOutfitAsksForPieces() {
        #expect(engine.recommendation(for: [], closet: [snap(.top)]).change == nil)
    }

    @Test func suggestedNamesAreFriendly() {
        #expect(OutfitEngine.suggestedName(for: [snap(.top, "green"), snap(.bottom), snap(.outerwear)]) == "Green layered look")
        #expect(OutfitEngine.suggestedName(for: [snap(.dress, "pink")]) == "Pink dress look")
    }

    @Test func normalizedKeepsScorerOrderAndLimit() {
        let set = [snap(.shoes), snap(.accessory), snap(.bottom), snap(.outerwear), snap(.top)]
        let normalized = OutfitEngine.normalized(set)
        #expect(normalized.count == 4)
        #expect(normalized.first?.role == .top)
        #expect(!normalized.contains { $0.role == .accessory })
    }
}
