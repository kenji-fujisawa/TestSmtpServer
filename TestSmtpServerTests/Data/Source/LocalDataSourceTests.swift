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
    
    init() throws {
        let schema = Schema(LocalUser.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(self.container)
        
        self.users = [
            User(name: "user1", password: "pass1"),
            User(name: "user2", password: "pass2"),
            User(name: "user3", password: "pass3")
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
}
