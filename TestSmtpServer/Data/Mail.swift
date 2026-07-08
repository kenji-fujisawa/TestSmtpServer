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
    
    struct Attachment: Equatable {
        var filename: String
        var data: Data
        
        init(filename: String = "", data: Data = Data()) {
            self.filename = filename
            self.data = data
        }
    }
    
    var id: UUID
    var mail: String
    var rcpt: [String]
    var data: String
    var from: Address?
    var to: [Address]
    var cc: [Address]
    var subject: String
    var body: [String]
    var attachments: [Attachment]
    var sent: Date?
    var received: Date?
    
    init(id: UUID = UUID(), mail: String = "", rcpt: [String] = [], data: String = "", from: Address? = nil, to: [Address] = [], cc: [Address] = [], subject: String = "", body: [String] = [], attachments: [Attachment] = [], sent: Date? = nil, received: Date? = nil) {
        self.id = id
        self.mail = mail
        self.rcpt = rcpt
        self.data = data
        self.from = from
        self.to = to
        self.cc = cc
        self.subject = subject
        self.body = body
        self.attachments = attachments
        self.sent = sent
        self.received = received
    }
}
