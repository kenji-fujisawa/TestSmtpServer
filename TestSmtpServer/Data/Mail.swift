//
//  Mail.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/22.
//

import Foundation

struct Mail: Equatable {
    struct Address: Equatable {
        var name: String
        var address: String
        
        init(name: String = "", address: String = "") {
            self.name = name
            self.address = address
        }
    }
    
    var id: UUID
    var from: Address?
    var to: [Address]
    var cc: [Address]
    var subject: String
    var body: String
    var received: Date
    
    init(id: UUID = UUID(), from: Address? = nil, to: [Address] = [], cc: [Address] = [], subject: String = "", body: String = "", received: Date = .now) {
        self.id = id
        self.from = from
        self.to = to
        self.cc = cc
        self.subject = subject
        self.body = body
        self.received = received
    }
}
