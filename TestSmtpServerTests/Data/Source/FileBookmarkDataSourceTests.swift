//
//  FileBookmarkDataSourceTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/15.
//

import Foundation
import Testing

@testable import TestSmtpServer

struct FileBookmarkDataSourceTests {

    @Test func testSaveLoadRemove() async throws {
        let inMemoryUserDefaults = UserDefaults()
        inMemoryUserDefaults.removeVolatileDomain(forName: UserDefaults.argumentDomain)
        let source = UserDefaultsBookmarkDataSource(inMemoryUserDefaults)
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tmp.txt")
        let text = "aaa"
        try text.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        
        let key = "tmp"
        try source.save(url: url, forKey: key)
        try source.load(forKey: key) { url in
            let result = try? String(contentsOf: url, encoding: .utf8)
            #expect(result == text)
        }
        
        source.remove(forKey: key)
        #expect(throws: UserDefaultsBookmarkDataSource.BookmarkError.notFound) {
            try source.load(forKey: key) { _ in }
        }
    }

}
