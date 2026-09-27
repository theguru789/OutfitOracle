//
//  ShopServiceTests.swift
//  OutfitOracleTests
//
//  The shopping feature must stay sustainability-first.
//

import Foundation
import Testing
@testable import OutfitOracle

struct ShopServiceTests {

    private let slot = TrendSlot(role: .outerwear, colors: ["brown"], patterns: [], fabrics: [], searchTerm: "wool coat")

    @Test func secondhandLinksComeFirst() {
        let links = ShopService.links(for: slot)
        #expect(links.first?.kind == .secondhand)
        #expect(links.first?.url.absoluteString.contains("brown%20wool%20coat") == true)
        // Order: all secondhand, then local, then sustainable brands
        let order: [ShopLink.Kind] = [.secondhand, .local, .sustainable]
        let ranks = links.map { order.firstIndex(of: $0.kind)! }
        #expect(ranks == ranks.sorted())
    }

    @Test func colorIsNotDuplicatedInTheQuery() {
        let already = TrendSlot(role: .top, colors: ["red"], patterns: [], fabrics: [], searchTerm: "red knit sweater")
        let url = ShopService.links(for: already).first!.url.absoluteString
        #expect(url.contains("red%20knit%20sweater"))
        #expect(!url.contains("red%20red"))
    }

    @Test func noFastFashionRetailers() {
        let banned = ["shein", "temu", "zara", "hm.com", "forever21", "fashionnova", "boohoo", "primark"]
        let all = ShopService.links(for: slot) + ShopService.donateLinks
        for link in all {
            let host = link.url.absoluteString.lowercased()
            #expect(!banned.contains { host.contains($0) }, "\(link.store)")
        }
    }

    @Test func allLinksAreSecure() {
        let all = ShopService.links(for: "floral dress") + ShopService.donateLinks
        #expect(all.allSatisfy { $0.url.scheme == "https" })
    }

    @Test func donateOptionsExist() {
        #expect(ShopService.donateLinks.count >= 2)
    }
}
