//
//  LogViewModelTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/22.
//

import Testing

@testable import TestSmtpServer

struct LogViewModelTests {

    @Test func testLog() async throws {
        let repository = FakeLogRepository()
        let viewModel = LogViewModel(repository)
        #expect(viewModel.log == "")
        
        var log = "aaa"
        repository.continuation?.yield(log)
        try await Task.sleep(for: .milliseconds(10))
        #expect(viewModel.log == log)
        
        log = "bbb"
        repository.continuation?.yield(log)
        try await Task.sleep(for: .milliseconds(10))
        #expect(viewModel.log == log)
    }
    
    class FakeLogRepository: LogRepository {
        var continuation: AsyncStream<String>.Continuation? = nil
        func getLogStream() -> AsyncStream<String> {
            return AsyncStream { continuation in
                self.continuation = continuation
            }
        }
        
        func getLog() -> String { "" }
    }
}
