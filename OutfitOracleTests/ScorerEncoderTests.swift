//
//  ScorerEncoderTests.swift
//  OutfitOracleTests
//
//  The Swift encoder must match train_scorer.py exactly, or OutfitScorer
//  receives garbage. These tests pin the layout.
//

import Testing
@testable import OutfitOracle

struct ScorerEncoderTests {

    @Test func dimensionsMatchTrainingScript() {
        #expect(ScorerEncoder.categories.count == 11)
        #expect(ScorerEncoder.colors.count == 12)
        #expect(ScorerEncoder.patterns.count == 9)
        #expect(ScorerEncoder.fabrics.count == 10)
        #expect(ScorerEncoder.itemDim == 42)
        #expect(ScorerEncoder.inputDim == 168)
        #expect(ScorerEncoder.encode(outfit: [snap(.top), snap(.bottom)]).count == 168)
    }

    @Test func listOrderMatchesTrainingScript() {
        // Copied from ~/Developer/OutfitOracle-ML/train_scorer.py
        #expect(ScorerEncoder.categories == ["accessories", "all-body", "bags", "bottoms", "hats",
                                             "jewellery", "outerwear", "scarves", "shoes", "sunglasses", "tops"])
        #expect(ScorerEncoder.colors == ["black", "white", "red", "blue", "green", "yellow",
                                         "pink", "grey", "brown", "orange", "purple", "navy"])
        #expect(ScorerEncoder.patterns == ["floral", "striped", "solid", "print", "graphic",
                                           "plaid", "checkered", "abstract", "geometric"])
        #expect(ScorerEncoder.fabrics == ["chiffon", "denim", "leather", "knit", "cotton",
                                          "silk", "lace", "velvet", "wool", "satin"])
    }

    @Test func oneHotSlotsAreInTheRightPlaces() {
        let vec = ScorerEncoder.encode(snap(.top, "navy", pattern: "striped", fabric: "denim"))
        let c = ScorerEncoder.categories.count, k = ScorerEncoder.colors.count, p = ScorerEncoder.patterns.count

        #expect(vec[ScorerEncoder.categories.firstIndex(of: "tops")!] == 1)
        #expect(vec[c + ScorerEncoder.colors.firstIndex(of: "navy")!] == 1)
        #expect(vec[c + k + ScorerEncoder.patterns.firstIndex(of: "striped")!] == 1)
        #expect(vec[c + k + p + ScorerEncoder.fabrics.firstIndex(of: "denim")!] == 1)
        #expect(vec.reduce(0, +) == 4)
    }

    @Test(arguments: GarmentRole.allCases)
    func everyRoleHasAScorerCategory(role: GarmentRole) {
        #expect(ScorerEncoder.categories.contains(role.polyvoreCategory))
    }

    @Test func unknownAttributesStayZero() {
        let vec = ScorerEncoder.encode(snap(.bottom, "unknown", pattern: "pleated", fabric: "unknown"))
        #expect(vec.reduce(0, +) == 1)   // only the category is set
    }

    @Test func outfitsArePaddedWithZeros() {
        let vec = ScorerEncoder.encode(outfit: [snap(.dress)])
        #expect(vec[ScorerEncoder.itemDim...].allSatisfy { $0 == 0 })
    }

    @Test func extraItemsBeyondFourAreDropped() {
        let five = [snap(.top), snap(.bottom), snap(.outerwear), snap(.shoes), snap(.accessory)]
        #expect(ScorerEncoder.encode(outfit: five).count == 168)
    }
}
