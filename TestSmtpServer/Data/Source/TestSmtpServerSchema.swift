//
//  TestSmtpServerSchema.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/26.
//

import SwiftData

struct TestSmtpServerSchema_v1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        TestSmtpServerSchema_v1.Mail_v1.self,
        TestSmtpServerSchema_v1.Mail_v1.Address_v1.self,
        TestSmtpServerSchema_v1.Mail_v1.Attachment_v1.self,
        TestSmtpServerSchema_v1.User_v1.self
    ]
}
