//
//  PersistenceTests.swift
//  OutfitOracleTests
//
//  SwiftData storage for the closet and wear history (in-memory only).
//

import Foundation
import SwiftData
import Testing
@testable import OutfitOracle

@MainActor
struct PersistenceTests {

    /// Kept alive for the whole test: SwiftData traps if the container is freed
    /// while its context or models are still in use.
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init() throws {
        container = try makeInMemoryContainer()
    }

    @Test func savesAndFetchesItems() throws {
        context.insert(WardrobeItem(croppedImageData: Data([1, 2, 3]), category: "trousers", color: "brown"))
        try context.save()

        let items = try context.fetch(FetchDescriptor<WardrobeItem>())
        #expect(items.count == 1)
        #expect(items.first?.role == .bottom)
        #expect(items.first?.croppedImageData == Data([1, 2, 3]))
    }

    @Test func archivedItemsAreHiddenFromTheCloset() throws {
        let kept = WardrobeItem(croppedImageData: Data(), category: "top")
        let gone = WardrobeItem(croppedImageData: Data(), category: "top")
        gone.isArchived = true
        context.insert(kept)
        context.insert(gone)
        try context.save()

        // Same predicate ClosetView uses
        let visible = try context.fetch(FetchDescriptor<WardrobeItem>(predicate: #Predicate { !$0.isArchived }))
        #expect(visible.map(\.id) == [kept.id])
    }

    @Test func wearLogsRememberWhatWasWorn() throws {
        let top = WardrobeItem(croppedImageData: Data(), category: "top")
        let bottom = WardrobeItem(croppedImageData: Data(), category: "trousers")
        context.insert(top)
        context.insert(bottom)
        let outfit = Outfit(items: [top.snapshot, bottom.snapshot], modelScore: 0.9, score: 0.9, reasons: [])

        ClosetContext.logWear(outfit, trendID: "denim-on-denim",
                              lookup: [top.id: top, bottom.id: bottom], in: context)

        let logs = try context.fetch(FetchDescriptor<WearLog>())
        #expect(logs.count == 1)
        #expect(Set(logs[0].itemIDs) == [top.id, bottom.id])
        #expect(logs[0].trendID == "denim-on-denim")
        #expect(top.wearCount == 1 && bottom.wearCount == 1)
    }

    @Test func recentSetsOnlyIncludeTheLastWeek() throws {
        let old = WearLog(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, itemIDs: [UUID()])
        let recent = WearLog(date: Date(), itemIDs: [UUID()])
        let closet = ClosetContext(items: [], logs: [old, recent])
        #expect(closet.recentSets == [Set(recent.itemIDs)])
    }

    @Test func sampleClosetLoadsForDemos() throws {
        SampleData.load(into: context)

        let items = try context.fetch(FetchDescriptor<WardrobeItem>())
        let logs = try context.fetch(FetchDescriptor<WearLog>())
        let outfits = try context.fetch(FetchDescriptor<SavedOutfit>())
        #expect(items.count == 22)
        #expect(logs.count == 3)
        #expect(outfits.count == 2)
        // Men's test closet: every type of piece except dresses
        #expect(Set(items.map(\.role)) == Set(GarmentRole.allCases).subtracting([.dress]))
        #expect(items.contains { $0.isForgotten })
        // Every sample is a real photo with the background already removed
        #expect(items.allSatisfy { $0.cutoutImageData != nil && $0.cutoutImage != nil })
        // A memory for "One year ago today"
        let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        #expect(logs.contains { abs($0.date.timeIntervalSince(yearAgo)) < 86_400 })
    }

    @Test func loadingTwiceDoesNotDuplicate() throws {
        SampleData.load(into: context)
        SampleData.load(into: context)
        #expect(try context.fetchCount(FetchDescriptor<WardrobeItem>()) == 22)
        #expect(try context.fetchCount(FetchDescriptor<SavedOutfit>()) == 2)
    }
}
