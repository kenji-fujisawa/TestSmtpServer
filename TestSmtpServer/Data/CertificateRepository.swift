//
//  CertificateRepository.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/15.
//

import Foundation

protocol CertificateRepository {
    func save(certificate: URL, password: String, forKey key: String) throws
    func save(certificate: URL, forKey key: String) throws
    func save(password: String, forKey key: String) throws
    func load(forKey key: String, callback: (URL, String) -> Void) throws
    func remove(forKey key: String) throws
}

class DefaultCertificateRepository: CertificateRepository {
    private let bookmarkSource: FileBookmarkDataSource
    private let secureSource: SecureDataSource
    
    init(_ bookmarkSource: FileBookmarkDataSource, _ secureSource: SecureDataSource) {
        self.bookmarkSource = bookmarkSource
        self.secureSource = secureSource
    }
    
    func save(certificate: URL, password: String, forKey key: String) throws {
        try bookmarkSource.save(url: certificate, forKey: key)
        try secureSource.save(password, forKey: key)
    }
    
    func save(certificate: URL, forKey key: String) throws {
        try bookmarkSource.save(url: certificate, forKey: key)
    }
    
    func save(password: String, forKey key: String) throws {
        try secureSource.save(password, forKey: key)
    }
    
    func load(forKey key: String, callback: (URL, String) -> Void) throws {
        let password = try secureSource.load(forKey: key)
        try bookmarkSource.load(forKey: key) { url in
            callback(url, password)
        }
    }
    
    func remove(forKey key: String) throws {
        bookmarkSource.remove(forKey: key)
        try secureSource.remove(forKey: key)
    }
}
