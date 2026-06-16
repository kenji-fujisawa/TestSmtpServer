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
    
    @Test func testRegister() async throws {
        let source = DefaultLocalDataSource(context)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "user"
        let pass = "pass"
        try await repository.register(name: name, password: pass)
        
        let user = try source.getUser(name: name)
        #expect(user != nil)
        #expect(user?.name == name)
        #expect(user?.password == pass)
    }
    
    @Test func testRegister_duplicate() async throws {
        let source = DefaultLocalDataSource(context)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "user"
        let pass = "pass"
        let user = User(name: name, password: pass)
        try source.insert(user)
        
        await #expect(throws: DefaultUserRepository.RegisterError.duplicateUser) {
            try await repository.register(name: name, password: pass)
        }
    }
    
    @Test func testRegister_invalidPassword() async throws {
        let source = DefaultLocalDataSource(context)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "user"
        let pass = ""
        
        await #expect(throws: DefaultUserRepository.RegisterError.invalidPassword) {
            try await repository.register(name: name, password: pass)
        }
    }
    
    @Test func testAuthenticate() async throws {
        let source = DefaultLocalDataSource(context)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "user"
        let pass = "pass"
        let user = User(name: name, password: pass)
        try source.insert(user)
        
        #expect(try await repository.authenticate(name: name, password: pass) == true)
    }
    
    @Test func testAuthenticate_fail() async throws {
        let source = DefaultLocalDataSource(context)
        let hasher = FakePasswordHasher()
        let repository = DefaultUserRepository(source, hasher)
        
        let name = "user"
        let pass = "pass"
        let user = User(name: name, password: pass)
        try source.insert(user)
        
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
