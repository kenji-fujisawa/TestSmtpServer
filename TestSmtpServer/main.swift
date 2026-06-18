//
//  main.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/18.
//

import Foundation
import SwiftUI

#if DEBUG
if CommandLine.arguments.contains("-UITests") {
    UITestApp.main()
} else {
    TestSmtpServerApp.main()
}
#else
TestSmtpServerApp.main()
#endif
