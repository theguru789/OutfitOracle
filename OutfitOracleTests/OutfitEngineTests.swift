//
//  OutfitEngineTests.swift
//  OutfitOracleTests
//

import Foundation
import Testing
@testable import OutfitOracle

struct OutfitEngineTests {

    @Test func candidateSetsAreAlwaysWearable() {
        let closet = [snap(.top), snap(.top, "white"), snap(.bottom), snap(.bottom, "blue"),
                      snap(.dress, "pink"), snap(.outerwear), snap(.shoes), snap(.accessory)]
        let sets = OutfitEngine.candidateSets(from: closet)
        #expect(!sets.isEmpty)

        for set in sets {
            let roles = set.map(\.role)
            let count = { (r: GarmentRole) in roles.filter { $0 == r }.count }
            #expect(set.count <= 4)
            #expect(count(.top) <= 1 && count(.bottom) <= 1 && count(.dress) <= 1)
            #expect(count(.outerwear) <= 1 && count(.shoes) <= 1 && count(.accessory) <= 1)
            // Either a dress, or a top + bottom — never a dress with a bottom
            if count(.dress) == 1 {
                #expect(count(.top) == 0 && count(.bottom) == 0)
            } else {
                #expect(count(.top) == 1 && count(.bottom) == 1)
            }
        }
    }

    @Test func noOutfitsWithoutABottomOrDress() {
        #expect(OutfitEngine.candidateSets(from: [snap(.top), snap(.shoes)]).isEmpty)
        #expect(OutfitEngine.candidateSets(from: []).isEmpty)
    }

    @Test func aSingleDressIsAnOutfit() {
        #expect(OutfitEngine.candidateSets(from: [snap(.dress)]).count == 1)
    }

    @Test func bigClosetsAreCappedForOlderPhones() {
        var closet: [ItemSnapshot] = []
        for _ in 0..<15 {
            closet += [snap(.top), snap(.bottom), snap(.outerwear), snap(.shoes)]
        }
        #expect(OutfitEngine.candidateSets(from: closet).count <= OutfitEngine.maxCandidates)
    }

    @Test func ruleScorePenalisesClashes() {
        let calm = OutfitEngine.ruleScore([snap(.top, "white"), snap(.bottom, "navy")])
        let clash = OutfitEngine.ruleScore([snap(.top, "red", pattern: "floral"),
                                            snap(.bottom, "green", pattern: "plaid")])
        #expect(calm > clash)
    }

    @Test func forgottenItemsGetABoost() {
        let engine = OutfitEngine()
        let fresh = [snap(.top, "white", days: 1), snap(.bottom, "navy", days: 1)]
        let forgotten = [snap(.top, "white", days: 60), snap(.bottom, "navy", days: 60)]
        let a = engine.score(fresh, trend: nil, weather: nil, favoriteColors: [], recentlyWorn: [])
        let b = engine.score(forgotten, trend: nil, weather: nil, favoriteColors: [], recentlyWorn: [])
        #expect(b.score > a.score)
        #expect(b.reasons.contains { $0.contains("not worn in 60 days") })
    }

    @Test func recentlyWornSetsArePenalised() {
        let engine = OutfitEngine()
        let set = [snap(.top), snap(.bottom)]
        let normal = engine.score(set, trend: nil, weather: nil, favoriteColors: [], recentlyWorn: [])
        let repeated = engine.score(set, trend: nil, weather: nil, favoriteColors: [],
                                    recentlyWorn: [Set(set.map(\.id))])
        #expect(repeated.score < normal.score)
    }

    @Test func coldWeatherPrefersALayer() {
        let engine = OutfitEngine()
        let cold = WeatherSnapshot(highC: 2, lowC: -4, symbol: "cloud.snow.fill")
        let top = snap(.top), bottom = snap(.bottom)
        let layered = engine.score([top, bottom, snap(.outerwear)], trend: nil, weather: cold, favoriteColors: [], recentlyWorn: [])
        let bare = engine.score([top, bottom], trend: nil, weather: cold, favoriteColors: [], recentlyWorn: [])
        #expect(layered.score - layered.modelScore > bare.score - bare.modelScore)
        #expect(layered.reasons.contains { $0.hasPrefix("Layered for") })
    }

    @Test func hotWeatherSkipsJackets() {
        let engine = OutfitEngine()
        let hot = WeatherSnapshot(highC: 32, lowC: 24, symbol: "sun.max.fill")
        let jacket = engine.score([snap(.top), snap(.bottom), snap(.outerwear)], trend: nil, weather: hot, favoriteColors: [], recentlyWorn: [])
        #expect(jacket.score < jacket.modelScore)
    }

    @Test func favoriteColorsGetASmallBoost() {
        let engine = OutfitEngine()
        let set = [snap(.top, "green"), snap(.bottom, "black")]
        let plain = engine.score(set, trend: nil, weather: nil, favoriteColors: [], recentlyWorn: [])
        let loved = engine.score(set, trend: nil, weather: nil, favoriteColors: ["green"], recentlyWorn: [])
        #expect(loved.score > plain.score)
    }

    @Test func trendTargetingFavorsMatchingOutfits() {
        let engine = OutfitEngine()
        let onTrend = [snap(.top, "white", fabric: "cotton"), snap(.bottom, "blue", fabric: "denim")]
        let offTrend = [snap(.top, "red", fabric: "knit"), snap(.bottom, "black", fabric: "wool")]
        let a = engine.score(onTrend, trend: denimLook, weather: nil, favoriteColors: [], recentlyWorn: [])
        let b = engine.score(offTrend, trend: denimLook, weather: nil, favoriteColors: [], recentlyWorn: [])
        #expect(a.score - a.modelScore > b.score - b.modelScore)
        #expect(a.reasons.contains("Fits the Denim on Denim trend"))
    }

    @Test func suggestionsRespectCountAndVariety() async {
        let closet = (0..<4).flatMap { _ in [snap(.top), snap(.bottom), snap(.shoes)] }
        let outfits = await OutfitEngine().suggestOutfits(from: closet, count: 5)
        #expect(!outfits.isEmpty && outfits.count <= 5)
        // No single piece shows up in more than 2 suggestions
        let uses = Dictionary(grouping: outfits.flatMap(\.itemIDs), by: { $0 }).mapValues(\.count)
        #expect(uses.values.allSatisfy { $0 <= 2 })
        // Sorted best first
        #expect(zip(outfits, outfits.dropFirst()).allSatisfy { $0.score >= $1.score })
    }

    @Test func percentIsClampedForDisplay() {
        let outfit = Outfit(items: [], modelScore: 1.3, score: 1.3, reasons: [])
        #expect(outfit.percent == 100)
    }
}
