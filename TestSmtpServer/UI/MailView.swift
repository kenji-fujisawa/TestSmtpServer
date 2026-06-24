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
                Text(mail.body)
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
                    from: "from1@test.com",
                    to: ["to1@test.com"],
                    subject: "subject1",
                    body: "body1",
                    received: Date(timeIntervalSinceNow: 0)
                ),
                Mail(
                    from: "from2@test.com",
                    to: ["to2_1@test.com", "to2_2@test.com"],
                    subject: "subject2",
                    body: "body2",
                    received: Date(timeIntervalSinceNow: -10)
                ),
                Mail(
                    from: "from3@test.com",
                    to: ["to3_1@test.com", "to3_2@test.com", "to3_3@test.com"],
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
