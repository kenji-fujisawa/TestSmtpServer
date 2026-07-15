//
//  NetworkSettingRepositoryTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/07/14.
//

import Testing

@testable import TestSmtpServer

struct NetworkSettingRepositoryTests {

    @Test func testPort() async throws {
        let source = FakeKeyValueDataSource()
        let repository = DefaultNetworkSettingRepository(source)
        #expect(repository.port == Constants.port)
        
        repository.port = 999
        #expect(repository.port == 999)
    }
    
    @Test func testBufferSize() async throws {
        let source = FakeKeyValueDataSource()
        let repository = DefaultNetworkSettingRepository(source)
        #expect(repository.bufferSize == Constants.bufferSize)
        
        repository.bufferSize = 999
        #expect(repository.bufferSize == 999)
    }
    
    class FakeKeyValueDataSource: KeyValueDataSource {
        private var values: [String: Int] = [:]
        
        func set(_ value: Int, forKey key: String) {
            values[key] = value
        }
        
        func integer(forKey key: String) -> Int? {
            values[key]
        }
    }
}
