//
//  DictionaryExtension.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/07/09.
//

import Foundation

extension Dictionary where Key == String {
    subscript(caseInsensitive key: Key) -> Value? {
        get {
            return self.first { $0.key.lowercased() == key.lowercased() }?.value
        }
    }
}
