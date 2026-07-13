//
//  CertificateSettingViewTests.swift
//  TestSmtpServerUITests
//
//  Created by uhimania on 2026/06/18.
//

import XCTest

final class CertificateSettingViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testInit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "CertificateSettingView", "initialValue"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.staticTexts["/aaa/bbb/ccc.pk12"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.secureTextFields["text_password"].waitForExistence(timeout: 3))
        
        let pass = app.secureTextFields["text_password"].value as? String
        XCTAssertEqual(pass?.count, 4)
    }
    
    func testCertificate() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "CertificateSettingView"]
        app.launch()
        app.activate()
        
        XCTAssertFalse(app.staticTexts["/aaa/bbb/ccc.pk12"].waitForExistence(timeout: 3))
        
        XCTAssertTrue(app.buttons["選択"].waitForExistence(timeout: 3))
        app.buttons["選択"].tap()
        
        XCTAssertTrue(app.staticTexts["/aaa/bbb/ccc.pk12"].waitForExistence(timeout: 3))
    }
    
    func testPassword() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "CertificateSettingView"]
        app.launch()
        app.activate()
        
        XCTAssertTrue(app.secureTextFields["text_password"].waitForExistence(timeout: 3))
        
        app.secureTextFields["text_password"].tap()
        app.secureTextFields["text_password"].typeText("pass")
        app.secureTextFields["text_password"].typeKey(.return, modifierFlags: [])
        app.buttons["update"].tap()
        XCTAssertEqual(app.staticTexts["check_password"].value as? String, "pass")
        
        app.secureTextFields["text_password"].tap()
        app.secureTextFields["text_password"].typeText("password")
        app.staticTexts["証明書を選択"].tap()
        app.buttons["update"].tap()
        XCTAssertEqual(app.staticTexts["check_password"].value as? String, "password")
    }
}
