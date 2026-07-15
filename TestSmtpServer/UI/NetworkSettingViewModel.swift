//
//  NetworkSettingViewModel.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/07/14.
//

import Foundation

@Observable
class NetworkSettingViewModel {
    var port: Int = 0
    var bufferSize: Int = 0
    
    @ObservationIgnored private var repository: NetworkSettingRepository
    
    init(_ repository: NetworkSettingRepository) {
        self.repository = repository
        
        self.port = repository.port
        self.bufferSize = repository.bufferSize
    }
    
    func updatePort(_ port: Int) {
        repository.port = port
        self.port = port
    }
    
    func updateBufferSize(_ size: Int) {
        repository.bufferSize = size
        self.bufferSize = size
    }
}
