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
    @State private var rawData: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            let leftWidth = proxy.size.width * 0.3
            let minLeftWidth = min(leftWidth, 180)
            
            HSplitView {
                List(selection: $selected) {
                    ForEach(viewModel.mails, id: \.id) { mail in
                        SidebarItem(mail: mail)
                            .tag(mail.id)
                    }
                }
                .frame(minWidth: minLeftWidth, idealWidth: leftWidth)
                
                VStack {
                    Group {
                        if let mail = viewModel.mails.first(where: { $0.id == selected }) {
                            if rawData {
                                RawDataView(mail: mail)
                            } else {
                                MailView(mail: mail)
                            }
                        } else {
                            if rawData {
                                RawDataView(mail: Mail())
                            } else {
                                MailView(mail: Mail())
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    if let error = viewModel.error {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(4)
                        .background(Color(red: 255/255, green: 228/255, blue: 222/255))
                        .clipShape(.buttonBorder)
                        .padding()
                    }
                }
                .layoutPriority(10)
                .toolbar {
                    ToolbarItem {
                        Toggle(isOn: $rawData) {
                            Text("RawData")
                        }
                        .toggleStyle(.button)
                    }
                }
            }
        }
    }
    
    private struct SidebarItem: View {
        let mail: Mail
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(mail.from?.displayName ?? "")
                    Spacer()
                    if let received = mail.received {
                        Text(received, format: .mail)
                            .foregroundStyle(.tertiary)
                    }
                }
                Text(mail.subject)
                    .foregroundStyle(.secondary)
                Text(mail.body)
                    .foregroundStyle(.tertiary)
            }
            .lineLimit(1)
        }
    }
    
    private struct MailView: View {
        let mail: Mail
        
        var body: some View {
            VStack {
                Header(mail: mail)
                
                Divider()
                
                ScrollView {
                    Text(mail.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
        }
    }
    
    private struct Header: View {
        let mail: Mail
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(mail.from?.displayName ?? "")
                        .bold()
                    Spacer()
                    if let received = mail.received {
                        Text(received, format: .mail)
                            .foregroundStyle(.tertiary)
                    }
                }
                Text(mail.subject)
                if !mail.to.isEmpty {
                    HStack {
                        Text("宛先: ")
                        Text(mail.to.map { $0.displayName }.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                    }
                }
                if !mail.cc.isEmpty {
                    HStack {
                        Text("cc: ")
                        Text(mail.cc.map { $0.displayName }.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private struct RawDataView: View {
        let mail: Mail
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Text("MAIL: ")
                        Text(mail.mail)
                    }
                    HStack(alignment: .top) {
                        Text("RCPT: ")
                        VStack {
                            ForEach (mail.rcpt, id: \.self) { rcpt in
                                Text(rcpt)
                            }
                        }
                    }
                    HStack(alignment: .top) {
                        Text("DATA: ")
                        Text(mail.data)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension Mail.Address {
    var displayName: String {
        name.isEmpty ? address : name
    }
}

private extension Date {
    struct MailFormatStyle: Foundation.FormatStyle {
        func format(_ value: Date) -> String {
            if Calendar.current.isDateInToday(value) {
                return value.formatted(.dateTime.hour().minute())
            } else {
                let components = Calendar.current.dateComponents([.day], from: value, to: .now)
                if let difference = components.day,
                   difference >= 0 && difference <= 2 {
                    return value.formatted(.relative(presentation: .named))
                } else {
                    return value.formatted(.dateTime.year().month().day())
                }
            }
        }
    }
}

private extension FormatStyle where Self == Date.MailFormatStyle {
    static var mail: Self { .init() }
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
                    mail: "mail1",
                    rcpt: ["rcpt1"],
                    data: "data1",
                    from: Mail.Address(name: "from1", address: "from1@test.com"),
                    to: [Mail.Address(name: "to1", address: "to1@test.com")],
                    cc: [Mail.Address(name: "cc1", address: "cc1@test.com")],
                    subject: "subject1",
                    body: "body1",
                    sent: Date(timeIntervalSinceNow: -10),
                    received: Date(timeIntervalSinceNow: 0)
                ),
                Mail(
                    mail: "mail2",
                    rcpt: ["rcpt2_1", "rcpt2_2"],
                    data: "data2",
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
                    sent: Date(timeIntervalSinceNow: -20),
                    received: Date(timeIntervalSinceNow: -10)
                ),
                Mail(
                    mail: "mail3",
                    rcpt: ["rcpt3_1", "rcpt3_2", "rcpt3_3"],
                    data: "data3",
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
                    sent: Date(timeIntervalSinceNow: -30),
                    received: Date(timeIntervalSinceNow: -20)
                )
            ]
            continuation.yield(mails)
        }
    }
    
    func getMails() throws -> [Mail] { [] }
    func add(_ mail: Mail) throws {}
}
