//
//  MailView.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/23.
//

import SwiftUI

struct MailView: View {
    let viewModel: MailViewModel
    @State private var selected: UUID? = nil
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selected) {
                ForEach(viewModel.mails, id: \.id) { mail in
                    VStack {
                        Text(mail.received, format: .dateTime.month().day().hour().minute())
                        Text(mail.subject)
                    }
                    .tag(mail.id)
                }
            }
        } detail: {
            if let mail = viewModel.mails.first(where: { $0.id == selected }) {
                VStack {
                    HStack {
                        Text("from: ")
                        Text(mail.from?.name ?? "")
                        Text("<\(mail.from?.address ?? "")>")
                    }
                    ForEach(mail.to, id: \.address) { to in
                        HStack {
                            Text("to: ")
                            Text(to.name)
                            Text("<\(to.address)>")
                        }
                    }
                    ForEach(mail.cc, id: \.address) { cc in
                        HStack {
                            Text("cc: ")
                            Text(cc.name)
                            Text("<\(cc.address)>")
                        }
                    }
                    Text(mail.body)
                }
            }
        }
    }
}

#Preview {
    let repository = FakeMailRepository()
    let viewModel = MailViewModel(repository)
    MailView(viewModel: viewModel)
}

private class FakeMailRepository: MailRepository {
    func getMailsStream() throws -> AsyncThrowingStream<[Mail], any Error> {
        AsyncThrowingStream { continuation in
            let mails = [
                Mail(
                    from: Mail.Address(name: "from1", address: "from1@test.com"),
                    to: [Mail.Address(name: "to1", address: "to1@test.com")],
                    cc: [Mail.Address(name: "cc1", address: "cc1@test.com")],
                    subject: "subject1",
                    body: "body1",
                    received: Date(timeIntervalSinceNow: 0)
                ),
                Mail(
                    from: Mail.Address(name: "from2", address: "from2@test.com"),
                    to: [
                        Mail.Address(name: "to2_1", address: "to2_1@test.com"),
                        Mail.Address(name: "to2_2", address: "to2_2@test.com")
                    ],
                    cc: [
                        Mail.Address(name: "cc2_1", address: "cc2_1@test.com"),
                        Mail.Address(name: "cc2_2", address: "cc2_2@test.com")
                    ],
                    subject: "subject2",
                    body: "body2",
                    received: Date(timeIntervalSinceNow: -10)
                ),
                Mail(
                    from: Mail.Address(name: "from3", address: "from3@test.com"),
                    to: [
                        Mail.Address(name: "to3_1", address: "to3_1@test.com"),
                        Mail.Address(name: "to3_2", address: "to3_2@test.com"),
                        Mail.Address(name: "to3_3", address: "to3_3@test.com")
                    ],
                    cc: [
                        Mail.Address(name: "cc3_1", address: "cc3_1@test.com"),
                        Mail.Address(name: "cc3_2", address: "cc3_2@test.com"),
                        Mail.Address(name: "cc3_3", address: "cc3_3@test.com")
                    ],
                    subject: "subject3",
                    body: "body3",
                    received: Date(timeIntervalSinceNow: -20)
                )
            ]
            continuation.yield(mails)
        }
    }
    
    func getMails() throws -> [Mail] { [] }
    func add(_ mail: Mail) throws {}
}
