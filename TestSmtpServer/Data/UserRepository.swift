//
//  UserRepository.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/15.
//

import Foundation

protocol UserRepository {
    func register(name: String, password: String) async throws
    func authenticate(name: String, password: String) async throws -> Bool
}

class DefaultUserRepository: UserRepository {
    enum RegisterError: Error {
        case duplicateUser
        case invalidPassword
    }
    
    let source: LocalDataSource
    let passwordHasher: PasswordHasher
    
    init(_ source: LocalDataSource, _ passwordHasher: PasswordHasher) {
        self.source = source
        self.passwordHasher = passwordHasher
    }
    
    func register(name: String, password: String) async throws {
        guard try source.getUser(name: name) == nil else { throw RegisterError.duplicateUser }
        guard !password.isEmpty else { throw RegisterError.invalidPassword }
        
        let user = User(
            name: name,
            password: try await passwordHasher.hash(password)
        )
        try source.insert(user)
    }
    
    func authenticate(name: String, password: String) async throws -> Bool {
        guard let user = try source.getUser(name: name) else { return false }
        
        return try await passwordHasher.verify(password: password, hash: user.password)
    }
}
