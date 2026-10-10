//
//  OutfitOracleNewFeatureUITests.swift
//  OutfitOracleUITests
//
//  Onboarding, sustainability impact, sharing, and About & Privacy.
//

import XCTest

final class OnboardingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingQuizSavesNameAndOpensCamera() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoCloset", "-showOnboarding"]
        app.launch()

        let fact = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '92 million tons'")).firstMatch
        XCTAssertTrue(fact.waitForExistence(timeout: 10))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["How it works"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()

        // About you: name + male / female
        let nameField = app.textFields["Your first name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Guru\n")
        app.buttons["Male"].tap()
        app.buttons["Next"].tap()

        // Your style: chips + own words
        XCTAssertTrue(app.staticTexts["Your style"].waitForExistence(timeout: 3))
        app.buttons["Green"].tap()
        let notes = app.textFields["e.g. comfy, earthy colors, no leather"]
        notes.tap()
        notes.typeText("comfy, no leather\n")
        app.buttons["Next"].tap()

        XCTAssertTrue(app.staticTexts["Private by design"].waitForExistence(timeout: 3))
        app.buttons["Snap my closet"].tap()

        // Lands on the Camera tab, and the answers were saved
        XCTAssertTrue(app.buttons["Upload"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Guru"].waitForExistence(timeout: 5))
    }

    /// Screenshots each intro page (Report navigator ▸ Attachments) and checks the
    /// last line of every page is fully on screen, above the Next/Skip buttons.
    @MainActor
    func testEveryIntroPageFitsOnScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoCloset", "-showOnboarding"]
        app.launch()

        let lastLines = [
            "92 million tons of clothes are thrown away every year.",
            "See how it works in detail",
            "Used to show the right section in shop links.",
            "In your own words",
            "Location is only used for weather.",
        ]
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 10))
        for (index, line) in lastLines.enumerated() {
            Thread.sleep(forTimeInterval: 1.2)   // let the slide-up / page-swipe animation finish
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Intro page \(index + 1)"
            attachment.lifetime = .keepAlways
            add(attachment)

            let element = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", line)).firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: 3), "page \(index + 1): '\(line)' missing")
            let button = index < lastLines.count - 1 ? app.buttons["Next"] : app.buttons["Snap my closet"]
            XCTAssertTrue(element.isHittable, "page \(index + 1): '\(line)' is off screen")
            // Must end above the page dots that sit just over the Next button
            XCTAssertLessThanOrEqual(element.frame.maxY, button.frame.minY - 30, "page \(index + 1): '\(line)' is hidden behind the page dots/buttons")
            if index < lastLines.count - 1 { app.buttons["Next"].tap() }
        }
    }

    @MainActor
    func testSkipGoesStraightToTheApp() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoCloset", "-showOnboarding"]
        app.launch()
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 10))
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.buttons["Explore trends"].waitForExistence(timeout: 5))
    }
}

final class NewFeatureUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-demoCloset"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    @MainActor
    func testStatsShowSustainabilityImpact() {
        app.buttons["See my weekly stats"].tap()
        XCTAssertTrue(app.staticTexts["Your sustainability impact"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Source: WRAP, Valuing Our Clothes (2012)"].exists)
    }

    @MainActor
    func testTodaysPickCanBeShared() {
        app.buttons["What should I\nwear today?"].tap()
        XCTAssertTrue(app.buttons["Wear this"].waitForExistence(timeout: 15))
        let share = app.buttons["Share"]
        XCTAssertTrue(share.waitForExistence(timeout: 5))
        share.tap()
        // The system share sheet appears
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 10)
                      || app.navigationBars["UIActivityContentView"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAboutAndPrivacyScreen() {
        app.tabBars.buttons["Profile"].tap()
        let about = app.buttons["About & Privacy"]
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        if !about.isHittable { app.swipeUp() }
        about.tap()
        XCTAssertTrue(app.staticTexts["Your privacy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Built with"].exists)
    }

    @MainActor
    func testHowItWorksOpensTheDetailedGuide() {
        app.tabBars.buttons["Profile"].tap()
        let guide = app.buttons["How it works"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        if !guide.isHittable { app.swipeUp() }
        guide.tap()
        XCTAssertTrue(app.navigationBars["How Outfit Oracle works"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1. Snap your closet"].exists)
    }

    @MainActor
    func testClosetOutfitsShowSavedOutfitsAndAdvice() {
        app.tabBars.buttons["Closet"].tap()
        app.buttons["Outfits"].tap()
        let saved = app.staticTexts["Weekend denim"]
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        saved.tap()
        XCTAssertTrue(app.staticTexts["Oracle recommends"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }

    @MainActor
    func testBuildAndNameAnOutfit() {
        app.tabBars.buttons["Closet"].tap()
        app.buttons["Outfits"].tap()
        app.buttons["New outfit"].tap()
        XCTAssertTrue(app.navigationBars["New outfit"].waitForExistence(timeout: 5))
        // Typing a name first keeps the app from auto-naming it
        let name = app.textFields["Name your outfit"]
        name.tap()
        name.typeText("All black\n")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Black tee'")).firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Dark wash jeans'")).firstMatch.tap()
        app.navigationBars["New outfit"].buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["All black"].waitForExistence(timeout: 5))
    }
}
