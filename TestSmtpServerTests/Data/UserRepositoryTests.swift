//
//  UserRepositoryTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/15.
//

import SwiftData
import Testing

@testable import TestSmtpServer

struct UserRepositoryTests {

    private let container: ModelContainer
    private let context: ModelContext
    
    init() throws {
        let schema = Schema(LocalUser.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(self.container)
    }
    
    @Test func testGetUsers() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let users = [
            User(name: "user1", password: "pass1"),
            User(name: "user2", password: "pass2"),
            User(name: "user3", password: "pass3")
        ]
        users.forEach { context.insert($0.asLocal()) }
        try context.save()
        
        let results = try await repository.getUsers()
        #expect(results.count == 3)
        #expect(results[0] == users[0])
        #expect(results[1] == users[1])
        #expect(results[2] == users[2])
    }
    
    @Test func testRegister() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "user"
        let pass = "pass"
        try await repository.register(name: name, password: pass)
        
        let user = try await source.getUser(name: name)
        #expect(user != nil)
        #expect(user?.name == name)
        #expect(user?.password == pass)
    }
    
    @Test func testRegister_duplicate() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "user"
        let pass = "pass"
        let user = User(name: name, password: pass)
        try await source.insert(user)
        
        await #expect(throws: DefaultUserRepository.RegisterError.duplicateUser) {
            try await repository.register(name: name, password: pass)
        }
    }
    
    @Test func testRegister_invalidName() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let pass = "pass"
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidName) {
            try await repository.register(name: "", password: pass)
        }
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidName) {
            try await repository.register(name: "   ", password: pass)
        }
    }
    
    @Test func testRegister_invalidPassword() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "user"
        let pass = ""
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidPassword) {
            try await repository.register(name: name, password: pass)
        }
    }
    
    @Test func testUnregister() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "name"
        context.insert(LocalUser(name: name, password: ""))
        try context.save()
        
        try await repository.unregister(name: name)
        
        let results = try context.fetch(FetchDescriptor<LocalUser>())
        #expect(results.count == 0)
    }
    
    @Test func testUnregister_notfound() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "name"
        context.insert(LocalUser(name: name, password: ""))
        try context.save()
        
        await #expect(throws: DefaultUserRepository.UnregisterError.notFound) {
            try await repository.unregister(name: "bbb")
        }
        
        let results = try context.fetch(FetchDescriptor<LocalUser>())
        #expect(results.count == 1)
    }
    
    @Test func testAuthenticate() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "user"
        let pass = "pass"
        let user = User(name: name, password: pass)
        try await source.insert(user)
        
        #expect(try await repository.authenticate(name: name, password: pass) == true)
    }
    
    @Test func testAuthenticate_fail() async throws {
        let source = DefaultLocalDataSource(modelContainer: container)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "user"
        let pass = "pass"
        let user = User(name: name, password: pass)
        try await source.insert(user)
        
        #expect(try await repository.authenticate(name: name, password: "aaa") == false)
    }
    
    class FakePasswordHasher: PasswordHasher {
        func hash(_ password: String) async throws -> String {
            password
        }
        
        func verify(password: String, hash: String) async throws -> Bool {
            password == hash
        }
    }
}
