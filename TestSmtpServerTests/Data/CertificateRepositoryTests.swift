//
//  CertificateRepositoryTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/15.
//

import Foundation
import Testing

@testable import TestSmtpServer

struct CertificateRepositoryTests {

    @Test func testSave() async throws {
        let bookmarkSource = FakeBookmarkDataSource()
        let secureSource = FakeSecureDataSource()
        let repository = DefaultCertificateRepository(bookmarkSource, secureSource)
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tmp.txt")
        let password = "pass"
        let key = "key"
        try repository.save(certificate: url, password: password, forKey: key)
        #expect(bookmarkSource.url == url)
        #expect(bookmarkSource.key == key)
        #expect(secureSource.value == password)
        #expect(secureSource.key == key)
        
        let url2 = FileManager.default.temporaryDirectory.appendingPathComponent("tmp2.txt")
        try repository.save(certificate: url2, forKey: key)
        #expect(bookmarkSource.url == url2)
        #expect(bookmarkSource.key == key)
        #expect(secureSource.value == password)
        #expect(secureSource.key == key)
        
        let password2 = "pass2"
        try repository.save(password: password2, forKey: key)
        #expect(bookmarkSource.url == url2)
        #expect(bookmarkSource.key == key)
        #expect(secureSource.value == password2)
        #expect(secureSource.key == key)
    }
    
    @Test func testLoad() async throws {
        let bookmarkSource = FakeBookmarkDataSource()
        let secureSource = FakeSecureDataSource()
        let repository = DefaultCertificateRepository(bookmarkSource, secureSource)
        
        bookmarkSource.url = FileManager.default.temporaryDirectory.appendingPathComponent("tmp.txt")
        secureSource.value = "pass"
        let key = "key"
        try repository.load(forKey: key) { url, password in
            #expect(url == bookmarkSource.url)
            #expect(password == secureSource.value)
        }
    }
    
    @Test func testRemove() async throws {
        let bookmarkSource = FakeBookmarkDataSource()
        let secureSource = FakeSecureDataSource()
        let repository = DefaultCertificateRepository(bookmarkSource, secureSource)
        
        let key = "key"
        try repository.remove(forKey: key)
        #expect(bookmarkSource.key == key)
        #expect(secureSource.key == key)
    }
    
    class FakeBookmarkDataSource: FileBookmarkDataSource {
        var url: URL? = nil
        var key: String? = nil
        
        func save(url: URL, forKey key: String) throws {
            self.url = url
            self.key = key
        }
        
        func load(forKey key: String, callback: (URL) throws -> Void) throws {
            self.key = key
            if let url = self.url {
                try callback(url)
            }
        }
        
        func remove(forKey key: String) {
            self.key = key
        }
    }
    
    class FakeSecureDataSource: SecureDataSource {
        var value: String? = nil
        var key: String? = nil
        
        func save(_ value: String, forKey key: String) throws {
            self.value = value
            self.key = key
        }
        
        func load(forKey key: String) throws -> String {
            self.key = key
            return value ?? ""
        }
        
        func remove(forKey key: String) throws {
            self.key = key
        }
    }
}
