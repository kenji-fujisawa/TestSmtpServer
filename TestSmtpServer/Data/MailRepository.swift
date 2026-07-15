//
//  MailRepository.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/22.
//

import Foundation
import SwiftData

protocol MailRepository {
    func getMailsStream() throws -> AsyncThrowingStream<[Mail], any Error>
    func getMails() async throws -> [Mail]
    func add(_ mail: Mail) async throws
    func remove(_ mail: Mail) async throws
}

class DefaultMailRepository: MailRepository {
    private let source: LocalDataSource
    
    init(_ source: LocalDataSource) {
        self.source = source
    }
    
    func getMailsStream() throws -> AsyncThrowingStream<[Mail], any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let mails = try await source.getMails()
                    continuation.yield(mails)
                } catch {
                    continuation.finish(throwing: error)
                    return
                }
                
                let notifications = NotificationCenter.default.notifications(named: ModelContext.didSave)
                for await _ in notifications {
                    do {
                        let mails = try await source.getMails()
                        continuation.yield(mails)
                    } catch {
                        continuation.finish(throwing: error)
                        break
                    }
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    func getMails() async throws -> [Mail] {
        try await source.getMails()
    }
    
    func add(_ mail: Mail) async throws {
        try await source.insert(mail)
    }
    
    func remove(_ mail: Mail) async throws {
        try await source.delete(mail)
    }
}
