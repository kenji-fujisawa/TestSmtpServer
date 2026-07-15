//
//  KeyValueDataSource.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/07/14.
//

import Foundation

protocol KeyValueDataSource {
    func set(_ value: Int, forKey key: String)
    func integer(forKey key: String) -> Int?
}

class UserDefaultsDataSource: KeyValueDataSource {
    private let userDefaults: UserDefaults
    
    init(_ userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func set(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func integer(forKey key: String) -> Int? {
        guard userDefaults.dictionaryRepresentation().keys.contains(key) else { return nil }
        return userDefaults.integer(forKey: key)
    }
}
