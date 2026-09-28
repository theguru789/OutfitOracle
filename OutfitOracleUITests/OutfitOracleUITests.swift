//
//  OutfitOracleUITests.swift
//  OutfitOracleUITests
//
//  Created by Guru Sanka on 2/9/26.
//

import XCTest

final class OutfitOracleUITests: XCTestCase {

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    /// Walks every screen with the sample closet and saves a screenshot of each
    /// (Xcode ▸ Report navigator ▸ this test ▸ Attachments). Handy for checking
    /// layouts on small and large iPhones and for demo slides.
    @MainActor
    func testDemoWalkthrough() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoCloset"]
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        snapshot("1-Home", app)

        // What should I wear today?
        app.buttons["What should I\nwear today?"].tap()
        XCTAssertTrue(app.buttons["Wear this"].waitForExistence(timeout: 15))
        snapshot("2-Today", app)
        app.buttons["Wear this"].tap()
        XCTAssertTrue(app.buttons["Logged — enjoy your day!"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()

        // Weekly stats
        app.buttons["See my weekly stats"].tap()
        XCTAssertTrue(app.staticTexts["total re-wears"].waitForExistence(timeout: 5))
        snapshot("3-Stats", app)
        app.buttons["Done"].tap()

        // Trends → first trend detail
        app.buttons["Explore trends"].tap()
        XCTAssertTrue(app.navigationBars["Trends"].waitForExistence(timeout: 5))
        snapshot("4-Trends", app)
        app.staticTexts["Denim on Denim"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Build it from my closet"].waitForExistence(timeout: 5))
        app.buttons["Build it from my closet"].tap()
        XCTAssertTrue(app.buttons["Wear this"].firstMatch.waitForExistence(timeout: 15))
        snapshot("5-TrendDetail", app)

        // Closet
        tabBar.buttons["Closet"].tap()
        XCTAssertTrue(app.staticTexts["My Closet"].waitForExistence(timeout: 5))
        snapshot("6-Closet", app)
        app.buttons["Tops"].tap()
        snapshot("7-Closet-Tops", app)

        // Chat (rule-based Oracle in the Simulator unless Apple Intelligence is on)
        tabBar.buttons["Chat"].tap()
        app.buttons["What should I wear today?"].tap()
        XCTAssertTrue(app.staticTexts["style match"].firstMatch.waitForExistence(timeout: 30))
        snapshot("8-Chat", app)

        // Camera
        tabBar.buttons["Camera"].tap()
        XCTAssertTrue(app.buttons["Upload"].waitForExistence(timeout: 5))
        snapshot("9-Camera", app)

        // Profile
        tabBar.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        snapshot("10-Profile", app)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    private func snapshot(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
