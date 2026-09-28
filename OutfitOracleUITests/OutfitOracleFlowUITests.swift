//
//  OutfitOracleFlowUITests.swift
//  OutfitOracleUITests
//
//  End-to-end checks of the main user flows, using the in-memory sample
//  closet (`-demoCloset`) so the real closet is never touched.
//

import XCTest

final class OutfitOracleFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-demoCloset"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    @MainActor
    func testAllTabsOpen() {
        let tabs = app.tabBars.firstMatch
        let expectations: [(tab: String, marker: XCUIElement)] = [
            ("Camera", app.buttons["Upload"]),
            ("Chat", app.textFields["Ask the Oracle..."]),
            ("Oracle", app.buttons["Explore trends"]),
            ("Closet", app.staticTexts["My Closet"]),
            ("Profile", app.buttons["Settings"]),
        ]
        for (tab, marker) in expectations {
            tabs.buttons[tab].tap()
            XCTAssertTrue(marker.waitForExistence(timeout: 5), "\(tab) tab didn't load")
        }
    }

    @MainActor
    func testClosetFiltersByType() {
        app.tabBars.firstMatch.buttons["Closet"].tap()
        XCTAssertTrue(app.staticTexts["14 items"].waitForExistence(timeout: 5))

        app.buttons["Tops"].tap()
        XCTAssertTrue(app.staticTexts["Red knit sweater"].exists)
        XCTAssertFalse(app.staticTexts["Straight leg jeans"].exists)

        app.buttons["Bottoms"].tap()
        XCTAssertTrue(app.staticTexts["Straight leg jeans"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Red knit sweater"].exists)
    }

    @MainActor
    func testWearArchiveAndRestoreAnItem() {
        app.tabBars.firstMatch.buttons["Closet"].tap()
        app.buttons["Tops"].tap()
        app.staticTexts["Red knit sweater"].firstMatch.tap()

        // Log a wear
        let wore = app.buttons["Wore it today"]
        XCTAssertTrue(wore.waitForExistence(timeout: 5))
        wore.tap()
        XCTAssertTrue(app.buttons["Logged — nice re-wear!"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["1"].exists, "wear count should be 1")

        // Archive it (pass it on instead of trashing it)
        app.buttons["Not wearing this anymore?"].tap()
        let archive = app.buttons["Just archive it"]
        XCTAssertTrue(archive.waitForExistence(timeout: 3))
        archive.tap()

        app.buttons["All"].tap()
        XCTAssertTrue(app.staticTexts["13 items"].waitForExistence(timeout: 5))

        // Restore from Profile ▸ Archives
        app.tabBars.firstMatch.buttons["Profile"].tap()
        app.buttons["Archives"].tap()
        let restore = app.buttons["Restore"]
        XCTAssertTrue(restore.waitForExistence(timeout: 5))
        restore.tap()
        XCTAssertTrue(app.staticTexts["Nothing archived"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()

        app.tabBars.firstMatch.buttons["Closet"].tap()
        XCTAssertTrue(app.staticTexts["14 items"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTodaysPicksCanBeWornAndShuffled() {
        app.buttons["What should I\nwear today?"].tap()
        let wear = app.buttons["Wear this"]
        XCTAssertTrue(wear.waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["style match"].firstMatch.exists)

        app.buttons["Shuffle"].tap()
        XCTAssertTrue(wear.waitForExistence(timeout: 15))
        wear.tap()
        XCTAssertTrue(app.buttons["Logged — enjoy your day!"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testTrendShowsCompleteTheLookLinks() {
        app.buttons["Explore trends"].tap()
        // Moto Edge needs a brown/black leather jacket + boots the sample closet partly lacks
        let moto = app.staticTexts["Moto Edge"].firstMatch
        for _ in 0..<5 where !moto.isHittable { app.swipeUp() }
        moto.tap()
        XCTAssertTrue(app.staticTexts["Complete the look"].waitForExistence(timeout: 5)
                      || app.staticTexts["You already own this whole look. No shopping needed!"].exists)
    }

    @MainActor
    func testChatAnswersATypedQuestion() {
        app.tabBars.firstMatch.buttons["Chat"].tap()
        let field = app.textFields["Ask the Oracle..."]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        // "\n" submits via the keyboard (its return key is also labeled Send)
        field.typeText("what's trending?\n")

        let predicate = NSPredicate(format: "label CONTAINS 'Trending this season' OR label CONTAINS[c] 'trend'")
        XCTAssertTrue(app.staticTexts.containing(predicate).element(boundBy: 1).waitForExistence(timeout: 30))
    }

    @MainActor
    func testManualModeForShoesAndAccessories() {
        app.tabBars.firstMatch.buttons["Camera"].tap()
        app.buttons["Add shoes or accessories manually"].tap()
        XCTAssertTrue(app.staticTexts["Adding shoes or accessories"].waitForExistence(timeout: 3))
        app.buttons["Back to auto-detect"].tap()
        XCTAssertTrue(app.staticTexts["Snap an outfit or a single piece"].waitForExistence(timeout: 3))
    }
}
