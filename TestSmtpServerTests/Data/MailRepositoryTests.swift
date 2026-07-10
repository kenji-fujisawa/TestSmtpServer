//
//  MailRepositoryTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/22.
//

import Foundation
import SwiftData
import Testing

@testable import TestSmtpServer

struct MailRepositoryTests {

    private let container: ModelContainer
    
    init() throws {
        let schema = Schema(LocalMail.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
    }
    
    @Test func testGetMailsStream() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let repository = DefaultMailRepository(source)
        
        let mails = [
            Mail(
                id: UUID(),
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
                id: UUID(),
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
                id: UUID(),
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
        try await source.insert(mails[0])
        
        var iterator = try repository.getMailsStream().makeAsyncIterator()
        var results = try await iterator.next()
        #expect(results?.count == 1)
        #expect(results?[0] == mails[0])
        
        try await source.insert(mails[1])
        
        results = try await iterator.next()
        #expect(results?.count == 2)
        #expect(results?[0] == mails[0])
        #expect(results?[1] == mails[1])
        
        try await source.insert(mails[2])
        
        results = try await iterator.next()
        #expect(results?.count == 3)
        #expect(results?[0] == mails[0])
        #expect(results?[1] == mails[1])
        #expect(results?[2] == mails[2])
    }
    
    @Test func testGetMails() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let repository = DefaultMailRepository(source)
        
        let mails = [
            Mail(
                id: UUID(),
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
                id: UUID(),
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
                id: UUID(),
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
        for mail in mails {
            try await source.insert(mail)
        }
        
        let results = try await repository.getMails()
        #expect(results.count == mails.count)
        #expect(results[0] == mails[0])
        #expect(results[1] == mails[1])
        #expect(results[2] == mails[2])
    }
    
    @Test func testAdd() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let repository = DefaultMailRepository(source)
        
        let mail = Mail(
            id: UUID(),
            mail: "mail",
            rcpt: ["rcpt"],
            data: "data",
            from: Mail.Address(name: "from", address: "from@test.com"),
            to: [
                Mail.Address(name: "to1", address: "to1@test.com"),
                Mail.Address(name: "to2", address: "to2@test.com")
            ],
            cc: [
                Mail.Address(name: "cc1", address: "cc1@test.com"),
                Mail.Address(name: "cc2", address: "cc2@test.com"),
                Mail.Address(name: "cc3", address: "cc3@test.com")
            ],
            subject: "subject",
            body: ["body"],
            attachments: [
                Mail.Attachment(
                    filename: "attach1",
                    data: "data1".data(using: .utf8) ?? Data()
                ),
                Mail.Attachment(
                    filename: "attach2",
                    data: "data2".data(using: .utf8) ?? Data()
                )
            ],
            sent: .now,
            received: .now
        )
        try await repository.add(mail)
        
        let results = try await source.getMails()
        #expect(results.count == 1)
        #expect(results[0] == mail)
    }
}
