//
//  ContentView.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/15.
//

import SwiftUI

struct ContentView: View {
    private enum SelectedView {
        case mailbox
        case certificate
        case user
        case network
        case log
    }
    
    let server: SessionServer<SmtpSession>
    @Environment(\.mailRepository) private var mailRepository
    @Environment(\.certificateRepository) private var certificateRepository
    @Environment(\.userRepository) private var userRepository
    @Environment(\.networkSettingRepository) private var networkSettingRepository
    @Environment(\.logRepository) private var logRepository
    @State private var selected: SelectedView = .mailbox
    @State private var serverRunning: Bool = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selected) {
                Label("メール", systemImage: "envelope.stack")
                    .tag(SelectedView.mailbox)
                Label("証明書", systemImage: "key.shield")
                    .tag(SelectedView.certificate)
                Label("ユーザ", systemImage: "person.and.person")
                    .tag(SelectedView.user)
                Label("ネットワーク", systemImage: "network")
                    .tag(SelectedView.network)
                Label("ログ", systemImage: "rectangle.and.pencil.and.ellipsis")
                    .tag(SelectedView.log)
            }
            .listStyle(.sidebar)
            
            Spacer()
            
            Button {
                if serverRunning {
                    server.stop()
                    serverRunning = false
                } else {
                    server.run()
                    serverRunning = true
                }
            } label: {
                if serverRunning {
                    Group {
                        Image(systemName: "square.fill")
                        Text("サーバー停止")
                    }
                    .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "play.fill")
                    Text("サーバー起動")
                }
            }
            .buttonStyle(.glass)
            .padding()
        } detail: {
            switch selected {
            case .mailbox:
                MailView(viewModel: MailViewModel(mailRepository))
                    .navigationTitle("メール")
            case .certificate:
                CertificateSettingView(viewModel: CertificateSettingViewModel(certificateRepository))
                    .navigationTitle("証明書設定")
            case .user:
                UserSettingView(viewModel: UserSettingViewModel(userRepository))
                    .navigationTitle("ユーザ設定")
            case .network:
                NetworkSettingView(viewModel: NetworkSettingViewModel(networkSettingRepository))
                    .navigationTitle("ネットワーク設定")
            case .log:
                LogView(viewModel: LogViewModel(logRepository))
                    .navigationTitle("ログ")
            }
        }
        .onAppear() {
            serverRunning = server.isRunning
        }
    }
}

#Preview {
    let cert = FakeCertificateRepository()
    let mail = FakeMailRepository()
    let user = FakeUserRepository()
    let net = FakeNetworkSettingRepository()
    let deps = SmtpDependencies(mail, user, net)
    let server = SessionServer<SmtpSession>(cert, net, deps)
    ContentView(server: server)
}

private class FakeCertificateRepository: CertificateRepository {
    func save(certificate: URL, password: String, forKey key: String) throws {}
    func save(certificate: URL, forKey key: String) throws {}
    func save(password: String, forKey key: String) throws {}
    func load(forKey key: String, callback: (URL, String) throws -> Void) throws {}
    func remove(forKey key: String) throws {}
}

private class FakeMailRepository: MailRepository {
    func getMailsStream() throws -> AsyncThrowingStream<[Mail], any Error> { AsyncThrowingStream { _ in } }
    func getMails() throws -> [Mail] { [] }
    func add(_ mail: Mail) throws {}
    func remove(_ mail: Mail) async throws {}
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
