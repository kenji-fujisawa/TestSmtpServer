//
//  LocalDataSource.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/15.
//

import Foundation
import SwiftData

protocol LocalDataSource {
    func getUsers() throws -> [User]
    func getUser(name: String) throws -> User?
    func insert(_ user: User) throws
    func update(_ user: User) throws
    func delete(_ user: User) throws
}

class DefaultLocalDataSource: LocalDataSource {
    private let context: ModelContext
    
    init(_ context: ModelContext) {
        self.context = context
    }
    
    func getUsers() throws -> [User] {
        let descriptor = FetchDescriptor<LocalUser>(
            sortBy: [.init(\.name)]
        )
        return try context.fetch(descriptor).map { $0.asUser() }
    }
    
    func getUser(name: String) throws -> User? {
        return try getLocalUser(name: name)?.asUser()
    }
    
    private func getLocalUser(name: String) throws -> LocalUser? {
        let descriptor = FetchDescriptor<LocalUser>(
            predicate: #Predicate { $0.name == name }
        )
        return try context.fetch(descriptor).first
    }
    
    func insert(_ user: User) throws {
        context.insert(user.asLocal())
        try context.save()
    }
    
    func update(_ user: User) throws {
        if let local = try getLocalUser(name: user.name) {
            local.password = user.password
            try context.save()
        }
    }
    
    func delete(_ user: User) throws {
        if let local = try getLocalUser(name: user.name) {
            context.delete(local)
            try context.save()
        }
    }
}

extension User {
    func asLocal() -> LocalUser {
        LocalUser(
            name: self.name,
            password: self.password
        )
    }
}

extension LocalUser {
    func asUser() -> User {
        User(
            name: self.name,
            password: self.password
        )
    }
}
