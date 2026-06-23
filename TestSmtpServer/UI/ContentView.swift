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
        case log
    }
    
    @Environment(\.mailRepository) private var mailRepository
    @Environment(\.certificateRepository) private var certificateRepository
    @Environment(\.userRepository) private var userRepository
    @Environment(\.logRepository) private var logRepository
    @State private var selected: SelectedView = .mailbox
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selected) {
                Label("メール", systemImage: "envelope.stack")
                    .tag(SelectedView.mailbox)
                Label("証明書", systemImage: "key.shield")
                    .tag(SelectedView.certificate)
                Label("ユーザ", systemImage: "person.and.person")
                    .tag(SelectedView.user)
                Label("ログ", systemImage: "rectangle.and.pencil.and.ellipsis")
                    .tag(SelectedView.log)
            }
            .listStyle(.sidebar)
        } detail: {
            switch selected {
            case .mailbox:
                MailView(viewModel: MailViewModel(mailRepository))
            case .certificate:
                CertificateSettingView(viewModel: CertificateSettingViewModel(certificateRepository))
            case .user:
                UserSettingView(viewModel: UserSettingViewModel(userRepository))
            case .log:
                LogView(viewModel: LogViewModel(logRepository))
            }
        }
    }
}

#Preview {
    ContentView()
}
