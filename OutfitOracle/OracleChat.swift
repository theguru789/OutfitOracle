//
//  OracleChat.swift
//  OutfitOracle
//
//  "Ask the Oracle". On iPhones with Apple Intelligence (iOS 26+) it uses Apple's
//  on-device language model with tools that read the closet. Every other iPhone
//  gets a rule-based Oracle that answers the same kinds of questions. Nothing
//  leaves the phone either way.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Snapshot of everything the Oracle may look at
nonisolated struct OracleContext: Sendable {
    var closet: [ItemSnapshot] = []
    var looks: [TrendLook] = []
    var weather: WeatherSnapshot?
    var favoriteColors: Set<String> = []
    var preferences: StylePreferences = .none
    var recentSets: [Set<UUID>] = []
}

/// Shared, thread-safe holder the chat tools read from
actor OracleDataStore {
    static let shared = OracleDataStore()
    private(set) var context = OracleContext()
    private(set) var lastOutfits: [Outfit] = []

    func update(_ context: OracleContext) { self.context = context }
    func setLastOutfits(_ outfits: [Outfit]) { lastOutfits = outfits }
    func takeLastOutfits() -> [Outfit] {
        defer { lastOutfits = [] }
        return lastOutfits
    }
}

// MARK: - Plain-text helpers shared by both modes
nonisolated enum OracleText {
    static func describe(_ item: ItemSnapshot) -> String {
        let worn = item.daysSinceWorn >= 30 ? ", not worn in \(item.daysSinceWorn) days" : ""
        return "\(item.name) (\(item.role.singular), \(item.color), \(item.pattern), \(item.fabric)\(worn))"
    }

    static func describe(_ outfit: Outfit) -> String {
        outfit.items.map(\.name).joined(separator: " + ") + " — \(outfit.percent)% match"
    }

    static func trendSummary(_ context: OracleContext) -> String {
        context.looks.map { look in
            let coverage = TrendMatcher.coverage(of: look, closet: context.closet)
            let missing = coverage.missing.map(\.searchTerm).joined(separator: ", ")
            return "\(look.name): \(coverage.summary)" + (missing.isEmpty ? " (complete!)" : "; missing: \(missing)")
        }.joined(separator: "\n")
    }
}

// MARK: - Mode selection
enum OracleMode {
    case onDevice, basic
}

@MainActor
final class OracleChat {
    private(set) var mode: OracleMode = .basic
    private var session: AnyObject?

    init() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            mode = .onDevice
            session = Self.makeSession()
        }
        #endif
    }

    /// Returns reply text + any outfits to show as cards
    func reply(to message: String) async -> (String, [Outfit]) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), mode == .onDevice, let session = session as? LanguageModelSession {
            do {
                let response = try await session.respond(to: message)
                let outfits = await OracleDataStore.shared.takeLastOutfits()
                return (response.content, outfits)
            } catch {
                // Guardrail / context errors → fall back to the rule-based answer
            }
        }
        #endif
        return await BasicOracle.reply(to: message)
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func makeSession() -> LanguageModelSession {
        var instructions = """
            You are the Outfit Oracle, a friendly personal stylist inside a wardrobe app \
            that fights textile waste. Always prefer outfits made from clothes the user already \
            owns. Encourage re-wearing forgotten pieces. Only suggest buying something when a \
            trend look is missing a piece, and then recommend secondhand first (thredUP, Depop, \
            Poshmark, local thrift) or sustainable brands, never fast fashion. \
            Use the tools to look at the user's closet and trends instead of guessing. \
            Keep replies short (2–4 sentences) and upbeat.
            """
        // What the user told us in the intro / Settings
        let notes = UserDefaults.standard.string(forKey: PrefKeys.styleNotes)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !notes.isEmpty {
            instructions += "\nThe user describes their style like this: \"\(notes)\". Respect it."
        }
        if Gender.current != .unspecified {
            instructions += "\nThe user is \(Gender.current.label.lowercased())."
        }
        return LanguageModelSession(
            tools: [GetClosetTool(), SuggestOutfitTool(), TrendsTool()],
            instructions: instructions
        )
    }
    #endif
}

// MARK: - Tools for the on-device model
#if canImport(FoundationModels)
@available(iOS 26.0, *)
struct GetClosetTool: Tool {
    let name = "getCloset"
    let description = "Lists the clothes in the user's closet with type, color, pattern, fabric and whether they've been forgotten."

    @Generable
    struct Arguments {
        @Guide(description: "Optional garment type to filter by: top, bottom, outerwear, dress, shoes, accessory. Empty for everything.")
        var role: String
    }

    func call(arguments: Arguments) async throws -> String {
        let context = await OracleDataStore.shared.context
        let role = GarmentRole(rawValue: arguments.role.lowercased())
        let items = context.closet.filter { role == nil || $0.role == role }
        if items.isEmpty { return "The closet has no matching items yet." }
        return items.prefix(40).map(OracleText.describe).joined(separator: "\n")
    }
}

@available(iOS 26.0, *)
struct SuggestOutfitTool: Tool {
    let name = "suggestOutfit"
    let description = "Builds and ranks outfits from the user's own clothes using the on-device compatibility model and today's weather. Optionally targets a trend."

    @Generable
    struct Arguments {
        @Guide(description: "Optional trend name to aim for, e.g. 'Denim on Denim'. Empty for no trend.")
        var trendName: String
    }

    func call(arguments: Arguments) async throws -> String {
        let context = await OracleDataStore.shared.context
        let trend = context.looks.first { $0.name.localizedCaseInsensitiveContains(arguments.trendName) && !arguments.trendName.isEmpty }
        let outfits = await OutfitEngine.shared.suggestOutfits(
            from: context.closet, trend: trend, weather: context.weather,
            recentlyWorn: context.recentSets, preferences: context.preferences, count: 3
        )
        await OracleDataStore.shared.setLastOutfits(outfits)
        if outfits.isEmpty { return "Not enough clothes yet. The user needs a top and a bottom, or a dress." }
        return outfits.map { OracleText.describe($0) + " — " + $0.reasons.joined(separator: "; ") }
            .joined(separator: "\n")
    }
}

@available(iOS 26.0, *)
struct TrendsTool: Tool {
    let name = "getTrends"
    let description = "Lists this season's trend looks, how many pieces of each the user already owns, and which pieces are missing."

    @Generable
    struct Arguments {
        @Guide(description: "Unused; pass an empty string.")
        var note: String
    }

    func call(arguments: Arguments) async throws -> String {
        let context = await OracleDataStore.shared.context
        return OracleText.trendSummary(context)
    }
}
#endif

// MARK: - Rule-based Oracle (works on every iPhone)
nonisolated enum BasicOracle {
    static let help = """
    I can help you:
    • “What should I wear today?”
    • “What’s trending?”
    • “What should I buy?” (secondhand first!)
    • “What have I forgotten about?”
    """

    static func reply(to message: String) async -> (String, [Outfit]) {
        let text = message.lowercased()
        let context = await OracleDataStore.shared.context

        func has(_ words: String...) -> Bool { words.contains { text.contains($0) } }

        if context.closet.isEmpty {
            return ("Your closet is empty right now. Snap a few pieces on the Camera tab and I'll start styling!", [])
        }

        if has("forgot", "haven't worn", "havent worn", "not worn", "unused", "rediscover") {
            let forgotten = context.closet.filter(\.isForgotten).sorted { $0.daysSinceWorn > $1.daysSinceWorn }
            guard !forgotten.isEmpty else {
                return ("You've worn everything in the last month. That's a sustainable closet! 🌱", [])
            }
            let list = forgotten.prefix(5).map { "• \($0.name) (\($0.daysSinceWorn) days)" }.joined(separator: "\n")
            let outfits = await suggest(context, count: 2)
            return ("These pieces miss you:\n\(list)\n\nHere's a way to bring them back:", outfits)
        }

        if has("buy", "shop", "missing", "need", "purchase", "get new") {
            let best = context.looks
                .map { TrendMatcher.coverage(of: $0, closet: context.closet) }
                .filter { !$0.missing.isEmpty }
                .max { $0.fraction < $1.fraction }
            guard let best else {
                return ("You already own every trend look. No shopping needed! 🌱", [])
            }
            let missing = best.missing.map(\.searchTerm).joined(separator: " and ")
            return ("You're closest to \(best.look.name) (\(best.summary.lowercased())). To finish it you'd only need \(missing). Try thredUP, Depop or a local thrift store first. Open Explore trends on the Oracle tab for links.", [])
        }

        if has("trend", "in style", "popular", "new", "season") {
            let coverages = context.looks.map { TrendMatcher.coverage(of: $0, closet: context.closet) }
                .sorted { $0.fraction > $1.fraction }
            let lines = coverages.prefix(3).map { "• \($0.look.name): \($0.summary.lowercased())" }.joined(separator: "\n")
            let top = coverages.first?.look
            let outfits = await suggest(context, trend: top, count: 1)
            return ("Trending this season:\n\(lines)\n\nHere's \(top?.name ?? "a trend") built from your closet:", outfits)
        }

        if has("wear", "outfit", "today", "dress me", "style", "look", "cold", "rain", "hot", "weather", "school", "work", "date") {
            let outfits = await suggest(context, count: 3)
            guard !outfits.isEmpty else {
                return ("I need at least a top and a bottom (or a dress) to build outfits.", [])
            }
            var intro = "Here are \(outfits.count) looks from your own closet"
            if let weather = context.weather {
                intro += " for \(WeatherService.format(weather.highC)) weather"
            }
            return (intro + ":", outfits)
        }

        if has("hi", "hello", "hey", "help", "what can you") {
            return ("Hi! I'm the Oracle. " + help, [])
        }

        return ("I'm not sure about that one yet. " + help, [])
    }

    private static func suggest(_ context: OracleContext, trend: TrendLook? = nil, count: Int) async -> [Outfit] {
        await OutfitEngine.shared.suggestOutfits(
            from: context.closet, trend: trend, weather: context.weather,
            recentlyWorn: context.recentSets, preferences: context.preferences, count: count
        )
    }
}
