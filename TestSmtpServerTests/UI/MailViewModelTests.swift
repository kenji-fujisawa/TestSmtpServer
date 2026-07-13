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
                mail: "mail1",
                rcpt: ["rcpt1"],
                data: "data1",
                from: Mail.Address(name: "from1", address: "from1@test.com"),
                to: [Mail.Address(name: "to1", address: "to1@test.com")],
                cc: [Mail.Address(name: "cc1", address: "cc1@test.com")],
                subject: "subject1",
                body: ["body1"],
                attachments: [
                    Mail.Attachment(
                        filename: "attach1",
                        data: "data1".data(using: .utf8) ?? Data()
                    )
                ],
                sent: Date(timeIntervalSinceNow: -10),
                received: Date(timeIntervalSinceNow: 0)
            ),
            Mail(
                mail: "mail2",
                rcpt: ["rcpt2_1", "rcpt2_2"],
                data: "data2",
                from: Mail.Address(name: "from2", address: "from2@test.com"),
                to: [
                    Mail.Address(name: "to2_1", address: "to2_1@test.com"),
                    Mail.Address(name: "to2_2", address: "to2_2@test.com")
                ],
                cc: [
                    Mail.Address(name: "cc2_1", address: "cc2_1@test.com"),
                    Mail.Address(name: "cc2_2", address: "cc2_2@test.com")
                ],
                subject: "subject2",
                body: ["body2_1", "body2_2"],
                attachments: [
                    Mail.Attachment(
                        filename: "attach2_1",
                        data: "data2_1".data(using: .utf8) ?? Data()
                    ),
                    Mail.Attachment(
                        filename: "attach2_2",
                        data: "data2_2".data(using: .utf8) ?? Data()
                    )
                ],
                sent: Date(timeIntervalSinceNow: -20),
                received: Date(timeIntervalSinceNow: -10)
            ),
            Mail(
                mail: "mail3",
                rcpt: ["rcpt3_1", "rcpt3_2", "rcpt3_3"],
                data: "data3",
                from: Mail.Address(name: "from3", address: "from3@test.com"),
                to: [
                    Mail.Address(name: "to3_1", address: "to3_1@test.com"),
                    Mail.Address(name: "to3_2", address: "to3_2@test.com"),
                    Mail.Address(name: "to3_3", address: "to3_3@test.com")
                ],
                cc: [
                    Mail.Address(name: "cc3_1", address: "cc3_1@test.com"),
                    Mail.Address(name: "cc3_2", address: "cc3_2@test.com"),
                    Mail.Address(name: "cc3_3", address: "cc3_3@test.com")
                ],
                subject: "subject3",
                body: ["body3_1", "body3_2", "body3_3"],
                attachments: [
                    Mail.Attachment(
                        filename: "attach3_1",
                        data: "data3_1".data(using: .utf8) ?? Data()
                    ),
                    Mail.Attachment(
                        filename: "attach3_2",
                        data: "data3_2".data(using: .utf8) ?? Data()
                    ),
                    Mail.Attachment(
                        filename: "attach3_3",
                        data: "data3_3".data(using: .utf8) ?? Data()
                    )
                ],
                sent: Date(timeIntervalSinceNow: -30),
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
    
    @Test func testRemove() async throws {
        let repository = FakeMailRepository()
        let viewModel = MailViewModel(repository)
        
        let mails = [
            Mail(received: Date(timeIntervalSinceNow: 0)),
            Mail(received: Date(timeIntervalSinceNow: -10)),
            Mail(received: Date(timeIntervalSinceNow: -20))
        ]
        try mails.forEach { try repository.add($0) }
        try await Task.sleep(for: .milliseconds(10))
        
        #expect(viewModel.mails.count == 3)
        #expect(viewModel.mails[0] == mails[0])
        #expect(viewModel.mails[1] == mails[1])
        #expect(viewModel.mails[2] == mails[2])
        
        viewModel.remove(mails[1])
        try await Task.sleep(for: .milliseconds(10))
        #expect(viewModel.mails.count == 2)
        #expect(viewModel.mails[0] == mails[0])
        #expect(viewModel.mails[1] == mails[2])
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
        
        func remove(_ mail: Mail) async throws {
            mails.removeAll { $0.id == mail.id }
            continuation?.yield(mails)
        }
    }
}
