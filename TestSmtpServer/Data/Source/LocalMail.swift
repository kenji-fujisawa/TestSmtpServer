//
//  LocalMail.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/22.
//

import Foundation
import SwiftData

@Model
class LocalMail {
    @Model
    class Address {
        var name: String
        var address: String
        var from: LocalMail?
        var to: LocalMail?
        var cc: LocalMail?
        
        init(name: String = "", address: String = "") {
            self.name = name
            self.address = address
        }
    }
    
    #Index<LocalMail>([\.id], [\.received])
    
    var id: UUID
    @Relationship(deleteRule: .cascade, inverse: \Address.from) var from: Address?
    @Relationship(deleteRule: .cascade, inverse: \Address.to) var to: [Address]
    @Relationship(deleteRule: .cascade, inverse: \Address.cc) var cc: [Address]
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
