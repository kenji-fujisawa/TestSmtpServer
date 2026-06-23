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
    func getMails() throws -> [Mail]
    func add(_ mail: Mail) throws
}

class DefaultMailRepository: MailRepository {
    private let source: LocalDataSource
    
    init(_ source: LocalDataSource) {
        self.source = source
    }
    
    func getMailsStream() throws -> AsyncThrowingStream<[Mail], any Error> {
        AsyncThrowingStream { continuation in
            do {
                let mails = try source.getMails()
                continuation.yield(mails)
            } catch {
                continuation.finish(throwing: error)
                return
            }
            
            let task = Task {
                let notifications = NotificationCenter.default.notifications(named: ModelContext.didSave)
                for await _ in notifications {
                    do {
                        let mails = try source.getMails()
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
    
    func getMails() throws -> [Mail] {
        try source.getMails()
    }
    
    func add(_ mail: Mail) throws {
        try source.insert(mail)
    }
}
