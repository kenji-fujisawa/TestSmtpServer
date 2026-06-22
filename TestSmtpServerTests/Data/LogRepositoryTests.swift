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
        var iterator = repository.getLogStream().makeAsyncIterator()
        
        logger.log("test")
        #expect(await iterator.next() == "test\n")
        
        logger.log("foo")
        #expect(await iterator.next() == "test\nfoo\n")
    }
    
    @Test func testGetLog() async throws {
        let logger = Logger()
        let repository = DefaultLogRepository(logger)
        
        logger.log("test")
        #expect(repository.getLog() == "test\n")
        
        logger.log("foo")
        #expect(repository.getLog() == "test\nfoo\n")
    }
}
