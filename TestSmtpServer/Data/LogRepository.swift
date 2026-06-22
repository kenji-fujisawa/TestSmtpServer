//
//  LogRepository.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/19.
//

import Combine
import Foundation

protocol LogRepository {
    func getLogStream() -> AsyncStream<String>
    func getLog() -> String
}

class DefaultLogRepository: LogRepository {
    private let logger: Logger
    
    init(_ logger: Logger) {
        self.logger = logger
    }
    
    func getLogStream() -> AsyncStream<String> {
        return AsyncStream { continuation in
            if !logger.log.isEmpty {
                continuation.yield(logger.log)
            }
            
            let cancellable = logger.subject.sink { log in
                continuation.yield(log)
            }
            
            continuation.onTermination = { @Sendable _ in
                cancellable.cancel()
            }
        }
    }
    
    func getLog() -> String {
        logger.log
    }
}
