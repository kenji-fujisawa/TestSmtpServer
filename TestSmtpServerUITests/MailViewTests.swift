//
//  MailViewTests.swift
//  TestSmtpServerUITests
//
//  Created by uhimania on 2026/06/23.
//

import XCTest

final class MailViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testInit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "MailView", "initialValue"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.staticTexts["Jun 23 at 12:00"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Jun 23 at 11:30"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Jun 23 at 11:00"].waitForExistence(timeout: 3))
        
        app.staticTexts["Jun 23 at 12:00"].tap()
        XCTAssertTrue(app.staticTexts["body1"].waitForExistence(timeout: 3))
        
        app.staticTexts["Jun 23 at 11:30"].tap()
        XCTAssertTrue(app.staticTexts["body2"].waitForExistence(timeout: 3))
        
        app.staticTexts["Jun 23 at 11:00"].tap()
        XCTAssertTrue(app.staticTexts["body3"].waitForExistence(timeout: 3))
    }
    
    func testReceiveMail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "MailView"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.buttons["add"].waitForExistence(timeout: 3))
        app.buttons["add"].tap()
        
        XCTAssertTrue(app.staticTexts["Jun 23 at 12:00"].waitForExistence(timeout: 3))
        app.staticTexts["Jun 23 at 12:00"].tap()
        
        XCTAssertTrue(app.staticTexts["body"].waitForExistence(timeout: 3))
    }
}
