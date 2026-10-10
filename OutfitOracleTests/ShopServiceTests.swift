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
        let links = ShopService.links(for: slot, gender: .unspecified)
        #expect(links.first?.kind == .secondhand)
        #expect(links.first?.url.absoluteString.contains("brown%20wool%20coat") == true)
        // Order: all secondhand, then local, then sustainable brands
        let order: [ShopLink.Kind] = [.secondhand, .local, .sustainable]
        let ranks = links.map { order.firstIndex(of: $0.kind)! }
        #expect(ranks == ranks.sorted())
    }

    @Test func colorIsNotDuplicatedInTheQuery() {
        let already = TrendSlot(role: .top, colors: ["red"], patterns: [], fabrics: [], searchTerm: "red knit sweater")
        let url = ShopService.links(for: already, gender: .unspecified).first!.url.absoluteString
        #expect(url.contains("red%20knit%20sweater"))
        #expect(!url.contains("red%20red"))
    }

    @Test func noFastFashionRetailers() {
        let banned = ["shein", "temu", "zara", "hm.com", "forever21", "fashionnova", "boohoo", "primark"]
        let all = ShopService.links(for: slot, gender: .unspecified) + ShopService.donateLinks
        for link in all {
            let host = link.url.absoluteString.lowercased()
            #expect(!banned.contains { host.contains($0) }, "\(link.store)")
        }
    }

    @Test func allLinksAreSecure() {
        let all = ShopService.links(for: "floral dress") + ShopService.donateLinks
        #expect(all.allSatisfy { $0.url.scheme == "https" })
    }

    @Test func searchesUseTheRightSection() {
        let men = ShopService.links(for: slot, gender: .male).first!.url.absoluteString
        let women = ShopService.links(for: slot, gender: .female).first!.url.absoluteString
        #expect(men.contains("men's%20brown%20wool%20coat") || men.contains("men%27s%20brown%20wool%20coat"))
        #expect(women.contains("women"))
    }

    @Test func donateOptionsExist() {
        #expect(ShopService.donateLinks.count >= 2)
    }
}
