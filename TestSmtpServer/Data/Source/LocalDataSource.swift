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
    
    func getMails() throws -> [Mail]
    func insert(_ mail: Mail) throws
    func update(_ mail: Mail) throws
    func delete(_ mail: Mail) throws
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
    
    func getMails() throws -> [Mail] {
        let descriptor = FetchDescriptor<LocalMail>(
            sortBy: [.init(\.received, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.asMail() }
    }
    
    private func getLocalMail(id: UUID) throws -> LocalMail? {
        let descriptor = FetchDescriptor<LocalMail>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    func insert(_ mail: Mail) throws {
        context.insert(mail.asLocal())
        try context.save()
    }
    
    func update(_ mail: Mail) throws {
        if let local = try getLocalMail(id: mail.id) {
            local.mail = mail.mail
            local.rcpt = mail.rcpt
            local.data = mail.data
            local.from = mail.from?.asLocal()
            local.to = mail.to.map { $0.asLocal() }
            local.cc = mail.cc.map { $0.asLocal() }
            local.subject = mail.subject
            local.body = mail.body
            local.sent = mail.sent
            local.received = mail.received
            try context.save()
        }
    }
    
    func delete(_ mail: Mail) throws {
        if let local = try getLocalMail(id: mail.id) {
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

extension Mail {
    func asLocal() -> LocalMail {
        LocalMail(
            id: self.id,
            mail: self.mail,
            rcpt: self.rcpt,
            data: self.data,
            from: self.from?.asLocal(),
            to: self.to.map { $0.asLocal() },
            cc: self.cc.map { $0.asLocal() },
            subject: self.subject,
            body: self.body,
            sent: self.sent,
            received: self.received
        )
    }
}

extension Mail.Address {
    func asLocal() -> LocalMail.Address {
        LocalMail.Address(
            name: self.name,
            address: self.address
        )
    }
}

extension LocalMail {
    func asMail() -> Mail {
        Mail(
            id: self.id,
            mail: self.mail,
            rcpt: self.rcpt,
            data: self.data,
            from: self.from?.asMail(),
            to: self.to
                .sorted { $0.address < $1.address }
                .map { $0.asMail() },
            cc: self.cc
                .sorted { $0.address < $1.address }
                .map { $0.asMail() },
            subject: self.subject,
            body: self.body,
            sent: self.sent,
            received: self.received
        )
    }
}

extension LocalMail.Address {
    func asMail() -> Mail.Address {
        Mail.Address(
            name: self.name,
            address: self.address
        )
    }
}
