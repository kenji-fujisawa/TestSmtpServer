//
//  Mail.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/22.
//

import Foundation

struct Mail: Equatable {
    var id: UUID
    var from: String
    var to: [String]
    var body: String
    var received: Date
    
    init(id: UUID = UUID(), from: String, to: [String], body: String, received: Date) {
        self.id = id
        self.from = from
        self.to = to
        self.body = body
        self.received = received
    }
}
