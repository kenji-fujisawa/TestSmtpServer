//
//  NetworkSettingRepository.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/07/14.
//

import Foundation

protocol NetworkSettingRepository {
    var port: Int { get set }
    var bufferSize: Int { get set }
}

class DefaultNetworkSettingRepository: NetworkSettingRepository {
    private static let portKey = "port"
    private static let bufferSizeKey = "bufferSize"
    
    private let source: KeyValueDataSource
    
    init(_ source: KeyValueDataSource) {
        self.source = source
    }
    
    var port: Int {
        get {
            source.integer(forKey: DefaultNetworkSettingRepository.portKey) ?? Constants.port
        }
        set {
            source.set(newValue, forKey: DefaultNetworkSettingRepository.portKey)
        }
    }
    
    var bufferSize: Int {
        get {
            source.integer(forKey: DefaultNetworkSettingRepository.bufferSizeKey) ?? Constants.bufferSize
        }
        set {
            source.set(newValue, forKey: DefaultNetworkSettingRepository.bufferSizeKey)
        }
    }
}
