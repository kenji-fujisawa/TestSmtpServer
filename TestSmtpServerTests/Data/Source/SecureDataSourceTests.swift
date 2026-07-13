//
//  SecureDataSourceTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/15.
//

import Testing

@testable import TestSmtpServer

struct SecureDataSourceTests {

    @Test func testSaveLoadRemove() async throws {
        let source = KeyChainDataSource()
        
        let password = "pass"
        let key = "TestSmtpServer.Test"
        try source.save(password, forKey: key)
        #expect(try source.load(forKey: key) == password)
        
        try source.remove(forKey: key)
        #expect(throws: KeyChainDataSource.KeyChainAccessError.self) {
            try source.load(forKey: key)
        }
    }

}
