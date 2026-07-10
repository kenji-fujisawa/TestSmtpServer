//
//  UserRepository.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/15.
//

import Foundation

protocol UserRepository {
    func getUsers() async throws -> [User]
    func register(name: String, password: String) async throws
    func unregister(name: String) async throws
    func authenticate(name: String, password: String) async throws -> Bool
}

class DefaultUserRepository: UserRepository {
    enum RegisterError: Error {
        case duplicateUser
        case invalidName
        case invalidPassword
    }
    
    enum UnregisterError: Error {
        case notFound
    }
    
    let source: LocalDataSource
    let passwordHasher: PasswordHasher
    
    init(_ source: LocalDataSource, _ passwordHasher: PasswordHasher) {
        self.source = source
        self.passwordHasher = passwordHasher
    }
    
    func getUsers() async throws -> [User] {
        try await source.getUsers()
    }
    
    func register(name: String, password: String) async throws {
        guard try await source.getUser(name: name) == nil else { throw RegisterError.duplicateUser }
        guard name.allSatisfy({ $0.isWhitespace }) == false else { throw RegisterError.invalidName }
        guard !password.isEmpty else { throw RegisterError.invalidPassword }
        
        let user = User(
            name: name,
            password: try await passwordHasher.hash(password)
        )
        try await source.insert(user)
    }
    
    func unregister(name: String) async throws {
        guard let user = try await source.getUser(name: name) else { throw UnregisterError.notFound }
        
        try await source.delete(user)
    }
    
    func authenticate(name: String, password: String) async throws -> Bool {
        guard let user = try await source.getUser(name: name) else { return false }
        
        return try await passwordHasher.verify(password: password, hash: user.password)
    }
}
