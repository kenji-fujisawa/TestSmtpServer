//
//  KeyValueDataSourceTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/07/14.
//

import Foundation
import Testing

@testable import TestSmtpServer

class KeyValueDataSourceTests {

    private let suiteName = "KeyValueDataSourceTests"
    private let userDefaults: UserDefaults
    
    init() {
        if let userDefaults = UserDefaults(suiteName: suiteName) {
            self.userDefaults = userDefaults
        } else {
            fatalError()
        }
    }
    
    deinit {
        if var url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
            url = url
                .appendingPathComponent("Preferences")
                .appendingPathComponent("\(suiteName).plist")
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    @Test func testInteger() async throws {
        let source = UserDefaultsDataSource(userDefaults)
        
        let key = "testKey"
        #expect(source.integer(forKey: key) == nil)
        
        let value = 100
        source.set(value, forKey: key)
        #expect(source.integer(forKey: key) == value)
    }

}
