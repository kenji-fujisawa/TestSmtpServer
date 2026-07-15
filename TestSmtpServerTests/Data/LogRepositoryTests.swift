//
//  LogRepositoryTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/19.
//

import Testing

@testable import TestSmtpServer

struct LogRepositoryTests {

    @Test func testGetLogStream() async throws {
        let logger = Logger()
        let repository = DefaultLogRepository(logger)
        var iterator = await repository.getLogStream().makeAsyncIterator()
        
        await logger.log("test")
        #expect(await iterator.next() == "test\n")
        
        await logger.log("foo")
        #expect(await iterator.next() == "test\nfoo\n")
    }
    
    @Test func testGetLog() async throws {
        let logger = Logger()
        let repository = DefaultLogRepository(logger)
        
        await logger.log("test")
        #expect(await repository.getLog() == "test\n")
        
        await logger.log("foo")
        #expect(await repository.getLog() == "test\nfoo\n")
    }
}
