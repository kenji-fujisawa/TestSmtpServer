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
    private let mailRepository: MailRepository
    private let certificateRepository: CertificateRepository
    private let userRepository: UserRepository
    private let logRepository: LogRepository
    private let server: SessionServer<SmtpSession>
    
    init() {
        #if DEBUG
        let inMemory = true
        #else
        let inMemory = false
        #endif
        let schema = Schema(versionedSchema: TestSmtpServerSchema_v1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let localSource = DefaultLocalDataSource(container.mainContext)
        mailRepository = DefaultMailRepository(localSource)
        
        let bookmarkSource = UserDefaultsBookmarkDataSource()
        #if DEBUG
        let secureSource = FakeSecureDataSource()
        #else
        let secureSource = KeyChainDataSource()
        #endif
        certificateRepository = DefaultCertificateRepository(bookmarkSource, secureSource)
        
        let passwordHasher = Argon2PasswordHasher()
        userRepository = DefaultUserRepository(localSource, passwordHasher)
        
        logRepository = DefaultLogRepository(Logger.shared)
        
        let dependency = SmtpDependencies(mailRepository, userRepository)
        server = SessionServer<SmtpSession>(port: Constants.port, certificateRepository, dependency)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(server: server)
                .environment(\.mailRepository, mailRepository)
                .environment(\.certificateRepository, certificateRepository)
                .environment(\.userRepository, userRepository)
                .environment(\.logRepository, logRepository)
        }
    }
}

extension EnvironmentValues {
    @Entry var mailRepository: MailRepository = FakeMailRepository()
    @Entry var certificateRepository: CertificateRepository = FakeCertificateRepository()
    @Entry var userRepository: UserRepository = FakeUserRepository()
    @Entry var logRepository: LogRepository = FakeLogRepository()
}

private class FakeMailRepository: MailRepository {
    func getMailsStream() throws -> AsyncThrowingStream<[Mail], any Error> { AsyncThrowingStream { _ in } }
    func getMails() throws -> [Mail] { [] }
    func add(_ mail: Mail) throws {}
}

private class FakeCertificateRepository: CertificateRepository {
    func save(certificate: URL, password: String, forKey key: String) throws {}
    func save(certificate: URL, forKey key: String) throws {}
    func save(password: String, forKey key: String) throws {}
    func load(forKey key: String, callback: (URL, String) -> Void) throws {}
    func remove(forKey key: String) throws {}
}

private class FakeUserRepository: UserRepository {
    func getUsers() throws -> [User] { [] }
    func register(name: String, password: String) async throws {}
    func unregister(name: String) throws {}
    func authenticate(name: String, password: String) async throws -> Bool { false }
}

private class FakeLogRepository: LogRepository {
    func getLogStream() -> AsyncStream<String> { AsyncStream { _ in } }
    func getLog() -> String { "" }
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
    @State private var container: ModelContainer
    @State private var bookmarkSource: FileBookmarkDataSource
    @State private var secureSource: SecureDataSource
    @State private var localSource: LocalDataSource
    @State private var mailRepository: MailRepository
    @State private var certificateRepository: CertificateRepository
    @State private var userRepository: UserRepository
    @State private var logRepository: LogRepository
    @State private var tmpText: String = ""
    
    init() {
        do {
            let schema = Schema(versionedSchema: TestSmtpServerSchema_v1.self)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: config)
            
            let bookmarkSource = FakeBookmarkDataSource()
            let secureSource = FakeSecureDataSource()
            let localSource = DefaultLocalDataSource(container.mainContext)
            let hasher = Argon2PasswordHasher()
            let mailRepository = DefaultMailRepository(localSource)
            let certificateRepository = DefaultCertificateRepository(bookmarkSource, secureSource)
            let userRepository = DefaultUserRepository(localSource, hasher)
            let logRepository = DefaultLogRepository(Logger.shared)
            
            self.container = container
            self.bookmarkSource = bookmarkSource
            self.secureSource = secureSource
            self.localSource = localSource
            self.mailRepository = mailRepository
            self.certificateRepository = certificateRepository
            self.userRepository = userRepository
            self.logRepository = logRepository
        } catch {
            fatalError()
        }
        
        if CommandLine.arguments.contains("MailView") {
            if CommandLine.arguments.contains("initialValue") {
                let mails = [
                    LocalMail(subject: "sub1", body: ["body1"], received: Date(timeIntervalSinceNow: 0)),
                    LocalMail(subject: "sub2", body: ["body2"], received: Date(timeIntervalSinceNow: -10)),
                    LocalMail(subject: "sub3", body: ["body3"], received: Date(timeIntervalSinceNow: -20))
                ]
                mails.forEach { container.mainContext.insert($0) }
            }
        } else if CommandLine.arguments.contains("CertificateSettingView") {
            if CommandLine.arguments.contains("initialValue") {
                try? certificateRepository.save(certificate: URL(filePath: "/aaa/bbb/ccc.pk12"), password: "pass", forKey: Constants.certificateKey)
            }
        } else if CommandLine.arguments.contains("UserSettingView") {
            if CommandLine.arguments.contains("initialValue") {
                let users = [
                    LocalUser(name: "user1", password: "pass1"),
                    LocalUser(name: "user2", password: "pass2"),
                    LocalUser(name: "user3", password: "pass3")
                ]
                users.forEach { container.mainContext.insert($0) }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("MailView") {
                MailView(viewModel: MailViewModel(mailRepository))
                Button("add") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm"
                    let mail = Mail(subject: "subject", body: ["body"], received: .now)
                    try? mailRepository.add(mail)
                }
            } else if CommandLine.arguments.contains("CertificateSettingView") {
                CertificateSettingView(viewModel: CertificateSettingViewModel(certificateRepository), isUiTesting: true)
                Text(tmpText)
                    .accessibilityIdentifier("check_password")
                Button("update") {
                    if let text = try? secureSource.load(forKey: Constants.certificateKey) {
                        tmpText = text
                    }
                }
            } else if CommandLine.arguments.contains("LogView") {
                LogView(viewModel: LogViewModel(logRepository))
                Button("add") {
                    Task {
                        await Logger.shared.log("aaa")
                    }
                }
            } else if CommandLine.arguments.contains("UserSettingView") {
                UserSettingView(viewModel: UserSettingViewModel(userRepository))
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
