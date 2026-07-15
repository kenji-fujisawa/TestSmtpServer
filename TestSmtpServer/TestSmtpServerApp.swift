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
    static let bufferSize = 4096 * 1000
    static let certificateKey = Bundle.main.bundleIdentifier ?? "jp.uhimania.TestSmtpServer"
}

struct TestSmtpServerApp: App {
    private let container: ModelContainer
    private let mailRepository: MailRepository
    private let certificateRepository: CertificateRepository
    private let userRepository: UserRepository
    private let networkSettingRepository: NetworkSettingRepository
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
        
        let localSource = DefaultLocalDataSource(modelContainer: container)
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
        
        let keyValueSource = UserDefaultsDataSource()
        networkSettingRepository = DefaultNetworkSettingRepository(keyValueSource)
        
        logRepository = DefaultLogRepository(Logger.shared)
        
        let dependency = SmtpDependencies(mailRepository, userRepository, networkSettingRepository)
        server = SessionServer<SmtpSession>(certificateRepository, networkSettingRepository, dependency)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(server: server)
                .environment(\.mailRepository, mailRepository)
                .environment(\.certificateRepository, certificateRepository)
                .environment(\.userRepository, userRepository)
                .environment(\.networkSettingRepository, networkSettingRepository)
                .environment(\.logRepository, logRepository)
                .onDisappear() {
                    NSApplication.shared.terminate(nil)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(replacing: .undoRedo) {}
        }
    }
}

extension EnvironmentValues {
    @Entry var mailRepository: MailRepository = FakeMailRepository()
    @Entry var certificateRepository: CertificateRepository = FakeCertificateRepository()
    @Entry var userRepository: UserRepository = FakeUserRepository()
    @Entry var networkSettingRepository: NetworkSettingRepository = FakeNetworkSettingRepository()
    @Entry var logRepository: LogRepository = FakeLogRepository()
}

private class FakeMailRepository: MailRepository {
    func getMailsStream() throws -> AsyncThrowingStream<[Mail], any Error> { AsyncThrowingStream { _ in } }
    func getMails() throws -> [Mail] { [] }
    func add(_ mail: Mail) throws {}
    func remove(_ mail: Mail) async throws {}
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

private class FakeNetworkSettingRepository: NetworkSettingRepository {
    var port: Int { get { 0 } set {} }
    var bufferSize: Int { get { 0 } set {} }
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
    @State private var keyValueSource: KeyValueDataSource
    @State private var mailRepository: MailRepository
    @State private var certificateRepository: CertificateRepository
    @State private var userRepository: UserRepository
    @State private var networkSettingRepository: NetworkSettingRepository
    @State private var logRepository: LogRepository
    @State private var tmpText: String = ""
    
    init() {
        do {
            let schema = Schema(versionedSchema: TestSmtpServerSchema_v1.self)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: config)
            
            let bookmarkSource = FakeBookmarkDataSource()
            let secureSource = FakeSecureDataSource()
            let localSource = DefaultLocalDataSource(modelContainer: container)
            let keyValueSource = FakeKeyValueDataSource()
            let hasher = Argon2PasswordHasher()
            let mailRepository = DefaultMailRepository(localSource)
            let certificateRepository = DefaultCertificateRepository(bookmarkSource, secureSource)
            let userRepository = DefaultUserRepository(localSource, hasher)
            let networkSettingRepository = DefaultNetworkSettingRepository(keyValueSource)
            let logRepository = DefaultLogRepository(Logger.shared)
            
            self.container = container
            self.bookmarkSource = bookmarkSource
            self.secureSource = secureSource
            self.localSource = localSource
            self.keyValueSource = keyValueSource
            self.mailRepository = mailRepository
            self.certificateRepository = certificateRepository
            self.userRepository = userRepository
            self.networkSettingRepository = networkSettingRepository
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
                    Task {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm"
                        let mail = Mail(subject: "subject", body: ["body"], received: .now)
                        try? await mailRepository.add(mail)
                    }
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
            } else if CommandLine.arguments.contains("UserSettingView") {
                UserSettingView(viewModel: UserSettingViewModel(userRepository))
            } else if CommandLine.arguments.contains("NetworkSettingView") {
                NetworkSettingView(viewModel: NetworkSettingViewModel(networkSettingRepository))
                Text(tmpText)
                    .accessibilityIdentifier("check_value")
                Button("port") {
                    tmpText = String(networkSettingRepository.port)
                }
                Button("buffer") {
                    tmpText = String(networkSettingRepository.bufferSize)
                }
            } else if CommandLine.arguments.contains("LogView") {
                LogView(viewModel: LogViewModel(logRepository))
                Button("add") {
                    Task {
                        await Logger.shared.log("aaa")
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
    
    class FakeKeyValueDataSource: KeyValueDataSource {
        private var values: [String: Int] = [:]
        
        func set(_ value: Int, forKey key: String) {
            values[key] = value
        }
        
        func integer(forKey key: String) -> Int? {
            values[key]
        }
    }
}
#endif
