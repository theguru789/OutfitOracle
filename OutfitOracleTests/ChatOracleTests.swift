//
//  ChatOracleTests.swift
//  OutfitOracleTests
//
//  The rule-based Oracle is what most iPhones (and the Simulator) use, so it
//  needs to answer the suggested questions correctly. Serialized because it
//  shares OracleDataStore.shared.
//

import Foundation
import Testing
@testable import OutfitOracle

@Suite(.serialized)
struct BasicOracleTests {

    private func load(_ closet: [ItemSnapshot], weather: WeatherSnapshot? = nil) async {
        await OracleDataStore.shared.update(OracleContext(
            closet: closet, looks: [denimLook], weather: weather
        ))
    }

    private let closet = [
        snap(.top, "white", fabric: "cotton", days: 2, name: "White tee"),
        snap(.bottom, "blue", fabric: "denim", days: 1, name: "Jeans"),
        snap(.top, "red", fabric: "knit", days: 90, name: "Red sweater"),
        snap(.shoes, "white", fabric: "leather", days: 3, name: "Sneakers"),
    ]

    @Test func emptyClosetAsksForPhotos() async {
        await load([])
        let (text, outfits) = await BasicOracle.reply(to: "What should I wear today?")
        #expect(text.contains("closet is empty"))
        #expect(outfits.isEmpty)
    }

    @Test func whatToWearReturnsOutfitCards() async {
        await load(closet, weather: WeatherSnapshot(highC: 8, lowC: 2, symbol: "cloud.fill"))
        let (text, outfits) = await BasicOracle.reply(to: "What should I wear today?")
        #expect(text.hasPrefix("Here are"))
        #expect(!outfits.isEmpty)
    }

    @Test func trendingListsCoverage() async {
        await load(closet)
        let (text, _) = await BasicOracle.reply(to: "What's trending?")
        #expect(text.contains("Trending this season"))
        #expect(text.contains("Denim on Denim"))
    }

    @Test func shoppingSendsToSecondhandFirst() async {
        await load(closet)
        let (text, outfits) = await BasicOracle.reply(to: "What should I buy?")
        #expect(text.contains("denim jacket"))
        #expect(text.contains("thredUP"))
        #expect(outfits.isEmpty)
    }

    @Test func forgottenPiecesAreNamed() async {
        await load(closet)
        let (text, _) = await BasicOracle.reply(to: "What have I forgotten about?")
        #expect(text.contains("Red sweater"))
    }

    @Test func coldIsNotMistakenForForgotten() async {
        await load(closet)
        let (text, _) = await BasicOracle.reply(to: "it's cold, what should I wear")
        #expect(text.hasPrefix("Here are"))
    }

    @Test func unknownQuestionsGetHelp() async {
        await load(closet)
        let (text, _) = await BasicOracle.reply(to: "asdfgh")
        #expect(text.contains("I can help you"))
    }
}
