//
//  MailViewModel.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/23.
//

import Foundation

@Observable
class MailViewModel {
    var mails: [Mail] = []
    var error: String? = nil
    
    @ObservationIgnored private let mailRepository: MailRepository
    @ObservationIgnored private var task: Task<Void, Never>? = nil
    
    init(_ mailRepository: MailRepository) {
        self.mailRepository = mailRepository
        
        do {
            let stream = try mailRepository.getMailsStream()
            task = Task { @MainActor [weak self] in
                do {
                    for try await mails in stream {
                        self?.mails = mails
                    }
                } catch {
                    self?.error = error.localizedDescription
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    deinit {
        task?.cancel()
    }
    
    func remove(_ mail: Mail) {
        Task {
            do {
                try await mailRepository.remove(mail)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
