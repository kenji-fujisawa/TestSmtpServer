//
//  LogViewModel.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/19.
//

import Foundation

@Observable
class LogViewModel {
    var log: String = ""
    
    @ObservationIgnored private let logRepository: LogRepository
    @ObservationIgnored private var task: Task<Void, Never>? = nil
    
    init(_ logRepository: LogRepository) {
        self.logRepository = logRepository
        
        Task {
            let stream = await logRepository.getLogStream()
            task = Task { @MainActor [weak self] in
                for await log in stream {
                    self?.log = log
                }
            }
        }
    }
    
    deinit {
        task?.cancel()
    }
}
