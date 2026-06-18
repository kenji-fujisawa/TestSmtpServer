//
//  TestSmtpServerApp.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/15.
//

import SwiftData
import SwiftUI

enum Constants {
    static let port = 1025
    static let certificateKey = Bundle.main.bundleIdentifier ?? "jp.uhimania.TestSmtpServer"
}

struct TestSmtpServerApp: App {
    private let container: ModelContainer
    private let certificateRepository: CertificateRepository
    private let userRepository: UserRepository
    private let server: SessionServer<SmtpSession>
    
    init() {
        #if DEBUG
        let inMemory = true
        #else
        let inMemory = false
        #endif
        let schema = Schema(LocalUser.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let bookmarkSource = UserDefaultsBookmarkDataSource()
        #if DEBUG
        let secureSource = FakeSecureDataSource()
        #else
        let secureSource = KeyChainDataSource()
        #endif
        certificateRepository = DefaultCertificateRepository(bookmarkSource, secureSource)
        
        let localSource = DefaultLocalDataSource(container.mainContext)
        let passwordHasher = Argon2PasswordHasher()
        userRepository = DefaultUserRepository(localSource, passwordHasher)
        
        server = SessionServer<SmtpSession>(port: Constants.port, certificateRepository, userRepository)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.certificateRepository, certificateRepository)
        }
    }
}

extension EnvironmentValues {
    @Entry var certificateRepository: CertificateRepository = FakeCertificateRepository()
}

private class FakeCertificateRepository: CertificateRepository {
    func save(certificate: URL, password: String, forKey key: String) throws {}
    func save(certificate: URL, forKey key: String) throws {}
    func save(password: String, forKey key: String) throws {}
    func load(forKey key: String, callback: (URL, String) -> Void) throws {}
    func remove(forKey key: String) throws {}
}

private class FakeSecureDataSource: SecureDataSource {
    private var values: [String: String] = [:]
    
    func save(_ value: String, forKey key: String) throws {
        values[key] = value
    }
    
    func load(forKey key: String) throws -> String {
        values[key] ?? ""
    }
    
    func remove(forKey key: String) throws {
        values.removeValue(forKey: key)
    }
}

#if DEBUG
struct UITestApp: App {
    @State private var bookmarkSource: FileBookmarkDataSource
    @State private var secureSource: SecureDataSource
    @State private var certificateRepository: CertificateRepository
    @State private var tmpText: String = ""
    
    init() {
        let bookmarkSource = FakeBookmarkDataSource()
        let secureSource = FakeSecureDataSource()
        let certificateRepository = DefaultCertificateRepository(bookmarkSource, secureSource)
        
        self.bookmarkSource = bookmarkSource
        self.secureSource = secureSource
        self.certificateRepository = certificateRepository
        
        if CommandLine.arguments.contains("CertificateSettingView") {
            if CommandLine.arguments.contains("initialValue") {
                try? certificateRepository.save(certificate: URL(filePath: "/aaa/bbb/ccc.pk12"), password: "pass", forKey: Constants.certificateKey)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("CertificateSettingView") {
                CertificateSettingView(viewModel: CertificateSettingViewModel(certificateRepository), isUiTesting: true)
                Text(tmpText)
                    .accessibilityIdentifier("check_password")
                Button("update") {
                    if let text = try? secureSource.load(forKey: Constants.certificateKey) {
                        tmpText = text
                    }
                }
            }
        }
    }
    
    class FakeBookmarkDataSource: FileBookmarkDataSource {
        private var values: [String: URL] = [:]
        
        func save(url: URL, forKey key: String) throws {
            values[key] = url
        }
        
        func load(forKey key: String, callback: (URL) -> Void) throws {
            if let url = values[key] {
                callback(url)
            }
        }
        
        func remove(forKey key: String) {
            values.removeValue(forKey: key)
        }
    }
    
    class FakeSecureDataSource: SecureDataSource {
        private var values: [String: String] = [:]
        
        func save(_ value: String, forKey key: String) throws {
            values[key] = value
        }
        
        func load(forKey key: String) throws -> String {
            values[key] ?? ""
        }
        
        func remove(forKey key: String) throws {
            values.removeValue(forKey: key)
        }
    }
}
#endif
