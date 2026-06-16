//
//  FileBookmarkDataSource.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/15.
//

import Foundation

protocol FileBookmarkDataSource {
    func save(url: URL, forKey key: String) throws
    func load(forKey key: String, callback: (URL) -> Void) throws
    func remove(forKey key: String)
}

class UserDefaultsBookmarkDataSource: FileBookmarkDataSource {
    enum BookmarkError: Error {
        case accessDenied
        case notFound
        case isStale
    }
    
    let userDefaults: UserDefaults
    
    init(_ userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func save(url: URL, forKey key: String) throws {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
        let bookmark = try url.bookmarkData(options: .withSecurityScope)
        userDefaults.set(bookmark, forKey: key)
    }
    
    func load(forKey key: String, callback: (URL) -> Void) throws {
        guard let bookmark = userDefaults.data(forKey: key) else { throw BookmarkError.notFound }
        
        var isStale = false
        let url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
        guard isStale == false else { throw BookmarkError.isStale }
        
        guard url.startAccessingSecurityScopedResource() else { throw BookmarkError.accessDenied }
        defer { url.stopAccessingSecurityScopedResource() }
        callback(url)
    }
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
