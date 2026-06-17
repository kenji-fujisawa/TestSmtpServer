//
//  TestSmtpServerApp.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/15.
//

import SwiftUI

enum Constants {
    static let certificateKey = Bundle.main.bundleIdentifier ?? "jp.uhimania.TestSmtpServer"
}

@main
struct TestSmtpServerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
