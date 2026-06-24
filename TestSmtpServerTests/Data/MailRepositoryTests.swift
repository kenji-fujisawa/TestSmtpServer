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
    private let context: ModelContext
    
    init() throws {
        let schema = Schema(LocalMail.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(self.container)
    }
    
    @Test func testGetMailsStream() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultMailRepository(source)
        
        let mails = [
            Mail(
                id: UUID(),
                from: "from1@test.com",
                to: ["to1@test.com"],
                subject: "subject1",
                body: "body1",
                received: Date(timeIntervalSinceNow: 0)
            ),
            Mail(
                id: UUID(),
                from: "from2@test.com",
                to: ["to2_1@test.com", "to2_2@test.com"],
                subject: "subject2",
                body: "body2",
                received: Date(timeIntervalSinceNow: -10)
            ),
            Mail(
                id: UUID(),
                from: "from3@test.com",
                to: ["to3_1@test.com", "to3_2@test.com", "to3_3@test.com"],
                subject: "subject3",
                body: "body3",
                received: Date(timeIntervalSinceNow: -20)
            )
        ]
        try source.insert(mails[0])
        
        var iterator = try repository.getMailsStream().makeAsyncIterator()
        var results = try await iterator.next()
        #expect(results?.count == 1)
        #expect(results?[0] == mails[0])
        
        try source.insert(mails[1])
        
        results = try await iterator.next()
        #expect(results?.count == 2)
        #expect(results?[0] == mails[0])
        #expect(results?[1] == mails[1])
        
        try source.insert(mails[2])
        
        results = try await iterator.next()
        #expect(results?.count == 3)
        #expect(results?[0] == mails[0])
        #expect(results?[1] == mails[1])
        #expect(results?[2] == mails[2])
    }
    
    @Test func testGetMails() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultMailRepository(source)
        
        let mails = [
            Mail(
                id: UUID(),
                from: "from1@test.com",
                to: ["to1@test.com"],
                subject: "subject1",
                body: "body1",
                received: Date(timeIntervalSinceNow: 0)
            ),
            Mail(
                id: UUID(),
                from: "from2@test.com",
                to: ["to2_1@test.com", "to2_2@test.com"],
                subject: "subject2",
                body: "body2",
                received: Date(timeIntervalSinceNow: -10)
            ),
            Mail(
                id: UUID(),
                from: "from3@test.com",
                to: ["to3_1@test.com", "to3_2@test.com", "to3_3@test.com"],
                subject: "subject3",
                body: "body3",
                received: Date(timeIntervalSinceNow: -20)
            )
        ]
        try mails.forEach { try source.insert($0) }
        
        let results = try repository.getMails()
        #expect(results.count == mails.count)
        #expect(results[0] == mails[0])
        #expect(results[1] == mails[1])
        #expect(results[2] == mails[2])
    }
    
    @Test func testAdd() async throws {
        let source = DefaultLocalDataSource(context)
        let repository = DefaultMailRepository(source)
        
        let mail = Mail(
            id: UUID(),
            from: "from@test.com",
            to: ["to1@test.com", "to2@test.com"],
            subject: "subject",
            body: "body",
            received: .now
        )
        try repository.add(mail)
        
        let results = try source.getMails()
        #expect(results.count == 1)
        #expect(results[0] == mail)
    }
}
