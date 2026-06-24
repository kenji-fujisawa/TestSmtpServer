//
//  MailViewModelTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/23.
//

import Foundation
import Testing

@testable import TestSmtpServer

struct MailViewModelTests {

    @Test func testMails() async throws {
        let repository = FakeMailRepository()
        let viewModel = MailViewModel(repository)
        #expect(viewModel.mails.isEmpty == true)
        
        let mails = [
            Mail(
                from: "from1@test.com",
                to: ["to1@test.com"],
                subject: "subject1",
                body: "body1",
                received: Date(timeIntervalSinceNow: 0)
            ),
            Mail(
                from: "from2@test.com",
                to: ["to2_1@test.com", "to2_2@test.com"],
                subject: "subject2",
                body: "body2",
                received: Date(timeIntervalSinceNow: -10)
            ),
            Mail(
                from: "from3@test.com",
                to: ["to3_1@test.com", "to3_2@test.com", "to3_3@test.com"],
                subject: "subject3",
                body: "body3",
                received: Date(timeIntervalSinceNow: -20)
            )
        ]
        
        try repository.add(mails[0])
        try await Task.sleep(for: .milliseconds(10))
        #expect(viewModel.mails.count == 1)
        #expect(viewModel.mails[0] == mails[0])
        
        try repository.add(mails[1])
        try await Task.sleep(for: .milliseconds(10))
        #expect(viewModel.mails.count == 2)
        #expect(viewModel.mails[0] == mails[0])
        #expect(viewModel.mails[1] == mails[1])
        
        try repository.add(mails[2])
        try await Task.sleep(for: .milliseconds(10))
        #expect(viewModel.mails.count == 3)
        #expect(viewModel.mails[0] == mails[0])
        #expect(viewModel.mails[1] == mails[1])
        #expect(viewModel.mails[2] == mails[2])
    }
    
    class FakeMailRepository: MailRepository {
        private var mails: [Mail] = []
        private var continuation: AsyncThrowingStream<[Mail], any Error>.Continuation? = nil
        
        func getMailsStream() throws -> AsyncThrowingStream<[Mail], any Error> {
            AsyncThrowingStream { continuation in
                self.continuation = continuation
            }
        }
        
        func getMails() throws -> [Mail] { [] }
        
        func add(_ mail: Mail) throws {
            mails.append(mail)
            continuation?.yield(mails)
        }
    }
}
