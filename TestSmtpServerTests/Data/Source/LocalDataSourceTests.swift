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
        let schema = Schema(LocalUser.self, LocalMail.self)
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
    }
    
    @Test func testGetUsers() async throws {
        users.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        let results = try source.getUsers()
        #expect(results.count == 3)
        #expect(results[0] == users[0])
        #expect(results[1] == users[1])
        #expect(results[2] == users[2])
    }
    
    @Test func testGetUser() async throws {
        users.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        var result = try source.getUser(name: users[0].name)
        #expect(result == users[0])
        
        result = try source.getUser(name: users[1].name)
        #expect(result == users[1])
        
        result = try source.getUser(name: users[2].name)
        #expect(result == users[2])
        
        result = try source.getUser(name: "")
        #expect(result == nil)
    }
    
    @Test func testInsertUser() async throws {
        let source = DefaultLocalDataSource(context)
        try users.forEach { try source.insert($0) }
        
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
        
        let source = DefaultLocalDataSource(context)
        
        guard var user1 = try source.getUser(name: users[0].name) else {
            Issue.record()
            return
        }
        user1.password = "aaa"
        
        guard var user2 = try source.getUser(name: users[2].name) else {
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
        
        try source.update(user1)
        try source.update(user2)
        
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
        
        let source = DefaultLocalDataSource(context)
        
        guard let user = try source.getUser(name: users[1].name) else {
            Issue.record()
            return
        }
        try source.delete(user)
        
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
        
        let source = DefaultLocalDataSource(context)
        let results = try source.getMails()
        #expect(results.count == 3)
        #expect(results[0] == mails[0])
        #expect(results[1] == mails[1])
        #expect(results[2] == mails[2])
    }
    
    @Test func testInsertMail() async throws {
        let source = DefaultLocalDataSource(context)
        try mails.forEach { try source.insert($0) }
        
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
        
        let source = DefaultLocalDataSource(context)
        
        let mails = try source.getMails()
        
        var mail1 = mails[0]
        mail1.to = ["to1_1@test.com", "to1_2@test.com"]
        mail1.body = "test"
        
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
        
        try source.update(mail1)
        try source.update(mail2)
        
        results = try context.fetch(descriptor).map { $0.asMail() }
        #expect(results.count == 3)
        #expect(results[0] == mail2)
        #expect(results[1] == mails[1])
        #expect(results[2] == mail1)
        
        #expect(results[0].from == "from3@test.com")
        #expect(results[0].to == [])
        #expect(results[0].subject == "subject3")
        #expect(results[0].body == "body3")
        #expect(results[2].from == "from1@test.com")
        #expect(results[2].to == ["to1_1@test.com", "to1_2@test.com"])
        #expect(results[2].subject == "subject1")
        #expect(results[2].body == "test")
    }
    
    @Test func testDeleteMail() async throws {
        mails.forEach { context.insert($0.asLocal()) }
        
        let source = DefaultLocalDataSource(context)
        
        let mails = try source.getMails()
        try source.delete(mails[1])
        
        let descriptor = FetchDescriptor<LocalMail>(
            sortBy: [.init(\.received)]
        )
        let results = try context.fetch(descriptor).map { $0.asMail() }
        #expect(results.count == 2)
        #expect(results[0] == mails[2])
        #expect(results[1] == mails[0])
    }
}
