//
//  LogViewTests.swift
//  TestSmtpServerUITests
//
//  Created by uhimania on 2026/06/22.
//

import XCTest

final class LogViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testLogView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "LogView"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.buttons["add"].waitForExistence(timeout: 3))
        
        app.buttons["add"].tap()
        XCTAssertEqual(app.staticTexts.matching(identifier: "aaa").count, 1)
        
        app.buttons["add"].tap()
        XCTAssertEqual(app.staticTexts.matching(identifier: "aaa").count, 2)
        
        app.buttons["trash"].tap()
        XCTAssertEqual(app.staticTexts.matching(identifier: "aaa").count, 0)
    }
}
