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
}
