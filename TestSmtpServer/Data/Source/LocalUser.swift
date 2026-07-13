//
//  LocalUser.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/15.
//

import SwiftData

extension TestSmtpServerSchema_v1 {
    @Model
    class User_v1 {
        #Index<User_v1>([\.name])
        
        var name: String
        var password: String
        
        init(name: String, password: String) {
            self.name = name
            self.password = password
        }
    }
}

typealias LocalUser = TestSmtpServerSchema_v1.User_v1
