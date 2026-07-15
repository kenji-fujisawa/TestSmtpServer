//
//  UserSettingViewTests.swift
//  TestSmtpServerUITests
//
//  Created by uhimania on 2026/06/19.
//

import XCTest

final class UserSettingViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testInit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "UserSettingView", "initialValue"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.staticTexts["user1"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["user2"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["user3"].waitForExistence(timeout: 3))
    }
    
    func testAdd() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "UserSettingView"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.textFields["ユーザ名を入力"].waitForExistence(timeout: 3))
        app.textFields["ユーザ名を入力"].tap()
        app.textFields["ユーザ名を入力"].typeText("user1")
        app.secureTextFields["パスワードを入力"].tap()
        app.secureTextFields["パスワードを入力"].typeText("pass1")
        app.buttons["追加"].tap()
        XCTAssertTrue(app.staticTexts["user1"].waitForExistence(timeout: 1))
        
        app.textFields["ユーザ名を入力"].tap()
        app.textFields["ユーザ名を入力"].typeText("user2")
        app.secureTextFields["パスワードを入力"].tap()
        app.secureTextFields["パスワードを入力"].typeText("pass2")
        app.buttons["追加"].tap()
        XCTAssertTrue(app.staticTexts["user1"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.staticTexts["user2"].waitForExistence(timeout: 1))
    }
    
    func testRemove() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "UserSettingView", "initialValue"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.staticTexts["user1"].waitForExistence(timeout: 3))
        app.staticTexts["user1"].tap()
        app.buttons["削除"].tap()
        XCTAssertFalse(app.staticTexts["user1"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.staticTexts["user2"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.staticTexts["user3"].waitForExistence(timeout: 1))
        
        XCTAssertTrue(app.staticTexts["user3"].waitForExistence(timeout: 3))
        app.staticTexts["user3"].tap()
        app.buttons["削除"].tap()
        XCTAssertFalse(app.staticTexts["user1"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.staticTexts["user2"].waitForExistence(timeout: 1))
        XCTAssertFalse(app.staticTexts["user3"].waitForExistence(timeout: 1))
    }
}
