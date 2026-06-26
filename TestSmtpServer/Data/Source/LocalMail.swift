//
//  LocalMail.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/22.
//

import Foundation
import SwiftData

extension TestSmtpServerSchema_v1 {
    @Model
    class Mail_v1 {
        @Model
        class Address_v1 {
            var name: String
            var address: String
            var from: Mail_v1?
            var to: Mail_v1?
            var cc: Mail_v1?
            
            init(name: String = "", address: String = "") {
                self.name = name
                self.address = address
            }
        }
        
        typealias Address = Address_v1
        
        #Index<Mail_v1>([\.id], [\.received])
        
        var id: UUID
        @Relationship(deleteRule: .cascade, inverse: \Address_v1.from) var from: Address_v1?
        @Relationship(deleteRule: .cascade, inverse: \Address_v1.to) var to: [Address_v1]
        @Relationship(deleteRule: .cascade, inverse: \Address_v1.cc) var cc: [Address_v1]
        var subject: String
        var body: String
        var received: Date
        
        init(id: UUID = UUID(), from: Address_v1? = nil, to: [Address_v1] = [], cc: [Address_v1] = [], subject: String = "", body: String = "", received: Date = .now) {
            self.id = id
            self.from = from
            self.to = to
            self.cc = cc
            self.subject = subject
            self.body = body
            self.received = received
        }
    }
}

typealias LocalMail = TestSmtpServerSchema_v1.Mail_v1
