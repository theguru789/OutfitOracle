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

        XCTAssertTrue(app.staticTexts["92 million tons"].waitForExistence(timeout: 10))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["How it works"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()

        // Style quiz
        let nameField = app.textFields["Your first name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Guru\n")
        app.buttons["Green"].tap()
        app.buttons["Next"].tap()

        XCTAssertTrue(app.staticTexts["Private by design"].waitForExistence(timeout: 3))
        app.buttons["Snap my closet"].tap()

        // Lands on the Camera tab, and the quiz answers were saved
        XCTAssertTrue(app.buttons["Upload"].waitForExistence(timeout: 5))
        app.tabBars.firstMatch.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Guru"].waitForExistence(timeout: 5))
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
        app.tabBars.firstMatch.buttons["Profile"].tap()
        let about = app.buttons["About & Privacy"]
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        if !about.isHittable { app.swipeUp() }
        about.tap()
        XCTAssertTrue(app.staticTexts["Your privacy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Built with"].exists)
    }

    @MainActor
    func testHowItWorksReplaysTheIntro() {
        app.tabBars.firstMatch.buttons["Profile"].tap()
        let replay = app.buttons["How it works"]
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
        if !replay.isHittable { app.swipeUp() }
        replay.tap()
        XCTAssertTrue(app.staticTexts["92 million tons"].waitForExistence(timeout: 5))
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.buttons["About & Privacy"].waitForExistence(timeout: 5))
    }
}
