//
//  LocalUser.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/15.
//

import SwiftData

@Model
class LocalUser {
    #Index<LocalUser>([\.name])
    
    var name: String
    var password: String
    
    init(name: String, password: String) {
        self.name = name
        self.password = password
    }
}
