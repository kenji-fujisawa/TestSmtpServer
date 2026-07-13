//
//  LocalDataSourceTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/15.
//

import Foundation
import SwiftData
import Testing

@testable import TestSmtpServer

struct LocalDataSourceTests {

    private let container: ModelContainer
    private let context: ModelContext
    private let users: [User]
    private let mails: [Mail]
    
    init() throws {
        let schema = Schema(versionedSchema: TestSmtpServerSchema_v1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(self.container)
        
        self.users = [
            User(name: "user1", password: "pass1"),
            User(name: "user2", password: "pass2"),
            User(name: "user3", password: "pass3")
        ]
        
        self.mails = [
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
    }
    
    @Test func testGetUsers() async throws {
        users.forEach { context.insert($0.asLocal()) }
        try context.save()
        
        let source = DefaultLocalDataSource(modelContainer: container)
        let results = try await source.getUsers()
        #expect(results.count == 3)
        #expect(results[0] == users[0])
        #expect(results[1] == users[1])
        #expect(results[2] == users[2])
    }
    
    @Test func testGetUser() async throws {
        users.forEach { context.insert($0.asLocal()) }
        try context.save()
        
        let source = DefaultLocalDataSource(modelContainer: container)
        var result = try await source.getUser(name: users[0].name)
        #expect(result == users[0])
        
        result = try await source.getUser(name: users[1].name)
        #expect(result == users[1])
        
        result = try await source.getUser(name: users[2].name)
        #expect(result == users[2])
        
        result = try await source.getUser(name: "")
        #expect(result == nil)
    }
    
    @Test func testInsertUser() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        for user in users {
            try await source.insert(user)
        }
        
        let descriptor = FetchDescriptor<LocalUser>(
            sortBy: [.init(\.name)]
        )
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 3)
        #expect(results[0] == users[0])
        #expect(results[1] == users[1])
        #expect(results[2] == users[2])
    }
    
    @Test func testUpdateUser() async throws {
        users.forEach { context.insert($0.asLocal()) }
        try context.save()
        
        let source = DefaultLocalDataSource(modelContainer: container)
        
        guard var user1 = try await source.getUser(name: users[0].name) else {
            Issue.record()
            return
        }
        user1.password = "aaa"
        
        guard var user2 = try await source.getUser(name: users[2].name) else {
            Issue.record()
            return
        }
        user2.password = "ccc"
        
        let descriptor = FetchDescriptor<LocalUser>(
            sortBy: [.init(\.name)]
        )
        var results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 3)
        #expect(results[0] == users[0])
        #expect(results[1] == users[1])
        #expect(results[2] == users[2])
        
        try await source.update(user1)
        try await source.update(user2)
        
        results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 3)
        #expect(results[0] == user1)
        #expect(results[1] == users[1])
        #expect(results[2] == user2)
        
        #expect(results[0].name == "user1")
        #expect(results[0].password == "aaa")
        #expect(results[2].name == "user3")
        #expect(results[2].password == "ccc")
    }
    
    @Test func testDeleteUser() async throws {
        users.forEach { context.insert($0.asLocal()) }
        try context.save()
        
        let source = DefaultLocalDataSource(modelContainer: container)
        
        guard let user = try await source.getUser(name: users[1].name) else {
            Issue.record()
            return
        }
        try await source.delete(user)
        
        let descriptor = FetchDescriptor<LocalUser>(
            sortBy: [.init(\.name)]
        )
        let results = try context.fetch(descriptor).map { $0.asUser() }
        #expect(results.count == 2)
        #expect(results[0] == users[0])
        #expect(results[1] == users[2])
    }
    
    @Test func testGetMails() async throws {
        mails.forEach { context.insert($0.asLocal()) }
        try context.save()
        
        let source = DefaultLocalDataSource(modelContainer: container)
        let results = try await source.getMails()
        #expect(results.count == 3)
        #expect(results[0] == mails[0])
        #expect(results[1] == mails[1])
        #expect(results[2] == mails[2])
    }
    
    @Test func testInsertMail() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        for mail in mails {
            try await source.insert(mail)
        }
        
        let descriptor = FetchDescriptor<LocalMail>(
            sortBy: [.init(\.received)]
        )
        let results = try context.fetch(descriptor).map { $0.asMail() }
        #expect(results.count == 3)
        #expect(results[0] == mails[2])
        #expect(results[1] == mails[1])
        #expect(results[2] == mails[0])
    }
    
    @Test func testUpdateMail() async throws {
        mails.forEach { context.insert($0.asLocal()) }
        try context.save()
        
        let source = DefaultLocalDataSource(modelContainer: container)
        
        let mails = try await source.getMails()
        
        var mail1 = mails[0]
        mail1.to = [
            Mail.Address(name: "to1_1", address: "to1_1@test.com"),
            Mail.Address(name: "to1_2", address: "to1_2@test.com")
        ]
        mail1.body = ["test1", "test2"]
        mail1.attachments = [
            Mail.Attachment(
                filename: "attach1_1",
                data: "data1_1".data(using: .utf8) ?? Data()
            ),
            Mail.Attachment(
                filename: "attach1_2",
                data: "data1_2".data(using: .utf8) ?? Data()
            )
        ]
        
        var mail2 = mails[2]
        mail2.to = []
        
        let descriptor = FetchDescriptor<LocalMail>(
            sortBy: [.init(\.received)]
        )
        var results = try context.fetch(descriptor).map { $0.asMail() }
        #expect(results.count == 3)
        #expect(results[0] == mails[2])
        #expect(results[1] == mails[1])
        #expect(results[2] == mails[0])
        
        try await source.update(mail1)
        try await source.update(mail2)
        
        results = try context.fetch(descriptor).map { $0.asMail() }
        #expect(results.count == 3)
        #expect(results[0] == mail2)
        #expect(results[1] == mails[1])
        #expect(results[2] == mail1)
        
        #expect(results[0].from?.name == "from3")
        #expect(results[0].from?.address == "from3@test.com")
        #expect(results[0].to == [])
        #expect(results[0].cc == mails[2].cc)
        #expect(results[0].subject == "subject3")
        #expect(results[0].body == mails[2].body)
        #expect(results[0].attachments == mails[2].attachments)
        #expect(results[2].from?.name == "from1")
        #expect(results[2].from?.address == "from1@test.com")
        #expect(results[2].to.count == 2)
        #expect(results[2].to[0].name == "to1_1")
        #expect(results[2].to[0].address == "to1_1@test.com")
        #expect(results[2].to[1].name == "to1_2")
        #expect(results[2].to[1].address == "to1_2@test.com")
        #expect(results[2].cc == mails[0].cc)
        #expect(results[2].subject == "subject1")
        #expect(results[2].body.count == 2)
        #expect(results[2].body[0] == "test1")
        #expect(results[2].body[1] == "test2")
        #expect(results[2].attachments.count == 2)
        #expect(results[2].attachments[0].filename == "attach1_1")
        #expect(String(data: results[2].attachments[0].data, encoding: .utf8) == "data1_1")
        #expect(results[2].attachments[1].filename == "attach1_2")
        #expect(String(data: results[2].attachments[1].data, encoding: .utf8) == "data1_2")
    }
    
    @Test func testDeleteMail() async throws {
        mails.forEach { context.insert($0.asLocal()) }
        try context.save()
        
        let source = DefaultLocalDataSource(modelContainer: container)
        
        let mails = try await source.getMails()
        try await source.delete(mails[1])
        
        let descriptor = FetchDescriptor<LocalMail>(
            sortBy: [.init(\.received)]
        )
        let results = try context.fetch(descriptor).map { $0.asMail() }
        #expect(results.count == 2)
        #expect(results[0] == mails[2])
        #expect(results[1] == mails[0])
        
        let addressDescriptor = FetchDescriptor<LocalMail.Address>(
            sortBy: [.init(\.name)]
        )
        let addresses = try context.fetch(addressDescriptor).map { $0.asMail() }
        #expect(addresses.count == 10)
        #expect(addresses[0] == mails[0].cc[0])
        #expect(addresses[1] == mails[2].cc[0])
        #expect(addresses[2] == mails[2].cc[1])
        #expect(addresses[3] == mails[2].cc[2])
        #expect(addresses[4] == mails[0].from)
        #expect(addresses[5] == mails[2].from)
        #expect(addresses[6] == mails[0].to[0])
        #expect(addresses[7] == mails[2].to[0])
        #expect(addresses[8] == mails[2].to[1])
        #expect(addresses[9] == mails[2].to[2])
        
        let attachmentDescriptor = FetchDescriptor<LocalMail.Attachment>(
            sortBy: [.init(\.filename)]
        )
        let attachments = try context.fetch(attachmentDescriptor).map { $0.asMail() }
        #expect(attachments.count == 4)
        #expect(attachments[0] == mails[0].attachments[0])
        #expect(attachments[1] == mails[2].attachments[0])
        #expect(attachments[2] == mails[2].attachments[1])
        #expect(attachments[3] == mails[2].attachments[2])
    }
}
