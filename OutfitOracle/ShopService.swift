//
//  ShopService.swift
//  OutfitOracle
//
//  "Complete the look" shopping — secondhand first, then sustainable brands.
//  Fast-fashion retailers are intentionally left out.
//

import Foundation

nonisolated struct ShopLink: Identifiable, Hashable, Sendable {
    enum Kind: String, Sendable {
        case secondhand = "Secondhand"
        case local = "Shop local"
        case sustainable = "Sustainable brand"
    }

    let store: String
    let kind: Kind
    let url: URL
    let symbol: String

    var id: String { store + url.absoluteString }
}

nonisolated enum ShopService {
    static let tagline = "Shop secondhand first. Every reused piece keeps clothes out of landfills."

    /// Links for a missing trend piece, most sustainable first
    static func links(for slot: TrendSlot, gender: Gender = .current) -> [ShopLink] {
        let color = slot.colors.first.map { "\($0) " } ?? ""
        let term = slot.searchTerm.lowercased().hasPrefix(color.lowercased()) ? slot.searchTerm : color + slot.searchTerm
        // "men's" / "women's" from the intro so searches show the right section
        return links(for: [gender.shopPrefix, term].compactMap { $0 }.joined(separator: " "))
    }

    static func links(for query: String) -> [ShopLink] {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        var result: [ShopLink] = []

        func add(_ store: String, _ kind: ShopLink.Kind, _ symbol: String, _ urlString: String) {
            if let url = URL(string: urlString) {
                result.append(ShopLink(store: store, kind: kind, url: url, symbol: symbol))
            }
        }

        // 1. Secondhand marketplaces
        add("thredUP", .secondhand, "arrow.3.trianglepath", "https://www.thredup.com/products?search_text=\(q)")
        add("Depop", .secondhand, "arrow.3.trianglepath", "https://www.depop.com/search/?q=\(q)")
        add("Poshmark", .secondhand, "arrow.3.trianglepath", "https://poshmark.com/search?query=\(q)")
        // 2. Local thrift / consignment
        add("Nearby thrift stores", .local, "mappin.and.ellipse", "https://maps.apple.com/?q=thrift%20store")
        // 3. Sustainable brands
        add("Patagonia", .sustainable, "leaf", "https://www.patagonia.com/search/?q=\(q)")
        add("Pact (organic cotton)", .sustainable, "leaf", "https://www.google.com/search?q=site%3Awearpact.com%20\(q)")
        add("Quince", .sustainable, "leaf", "https://www.google.com/search?q=site%3Aquince.com%20\(q)")

        return result
    }

    /// Where to send clothes you're done with instead of the trash
    static let donateLinks: [ShopLink] = [
        ShopLink(store: "Sell on thredUP", kind: .secondhand,
                 url: URL(string: "https://www.thredup.com/cleanout")!, symbol: "arrow.3.trianglepath"),
        ShopLink(store: "Sell on Poshmark", kind: .secondhand,
                 url: URL(string: "https://poshmark.com/sell")!, symbol: "arrow.3.trianglepath"),
        ShopLink(store: "Donate nearby", kind: .local,
                 url: URL(string: "https://maps.apple.com/?q=clothing%20donation")!, symbol: "mappin.and.ellipse"),
    ]
}
