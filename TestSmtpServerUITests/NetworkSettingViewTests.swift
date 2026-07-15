//
//  NetworkSettingViewTests.swift
//  TestSmtpServerUITests
//
//  Created by uhimania on 2026/07/14.
//

import XCTest

final class NetworkSettingViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testInit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "NetworkSettingView"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.textFields["587"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["65,536"].waitForExistence(timeout: 3))
    }
    
    func testPort_enter() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "NetworkSettingView"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.textFields["587"].waitForExistence(timeout: 3))
        
        app.textFields["587"].doubleTap()
        app.textFields["587"].typeKey(.delete, modifierFlags: [])
        app.textFields["ポート番号を入力"].typeText("999")
        sleep(1)
        app.textFields["999"].typeKey(.return, modifierFlags: [])
        app.buttons["port"].tap()
        XCTAssertEqual(app.staticTexts["check_value"].value as? String, "999")
    }
    
    func testPort_focus() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "NetworkSettingView"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.textFields["587"].waitForExistence(timeout: 3))
        
        app.textFields["587"].doubleTap()
        app.textFields["587"].typeKey(.delete, modifierFlags: [])
        app.textFields["ポート番号を入力"].typeText("999")
        sleep(1)
        app.textFields["65,536"].tap()
        app.buttons["port"].tap()
        XCTAssertEqual(app.staticTexts["check_value"].value as? String, "999")
    }
    
    func testBufferSize_enter() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "NetworkSettingView"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.textFields["65,536"].waitForExistence(timeout: 3))
        
        app.textFields["65,536"].doubleTap()
        app.textFields["65,536"].typeKey(.delete, modifierFlags: [])
        app.textFields["バッファサイズを入力"].typeText("999")
        sleep(1)
        app.textFields["999"].typeKey(.return, modifierFlags: [])
        app.buttons["buffer"].tap()
        XCTAssertEqual(app.staticTexts["check_value"].value as? String, "999")
    }
    
    func testBufferSize_focus() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "NetworkSettingView"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.textFields["65,536"].waitForExistence(timeout: 3))
        
        app.textFields["65,536"].doubleTap()
        app.textFields["65,536"].typeKey(.delete, modifierFlags: [])
        app.textFields["バッファサイズを入力"].typeText("999")
        sleep(1)
        app.textFields["587"].tap()
        app.buttons["buffer"].tap()
        XCTAssertEqual(app.staticTexts["check_value"].value as? String, "999")
    }
}
