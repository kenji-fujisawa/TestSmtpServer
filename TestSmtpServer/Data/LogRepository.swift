//
//  LogRepository.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/19.
//

import Foundation

protocol LogRepository {
    func getLogStream() async -> AsyncStream<String>
    func getLog() async -> String
    func clear() async
}

class DefaultLogRepository: LogRepository {
    private let logger: Logger
    
    init(_ logger: Logger) {
        self.logger = logger
    }
    
    func getLogStream() async -> AsyncStream<String> {
        await logger.getLogStream()
    }
    
    func getLog() async -> String {
        await logger.log
    }
    
    func clear() async {
        await logger.clear()
    }
}
