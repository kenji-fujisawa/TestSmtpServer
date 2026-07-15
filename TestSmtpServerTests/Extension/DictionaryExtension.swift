//
//  DictionaryExtension.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/07/09.
//

import Testing

@testable import TestSmtpServer

struct DictionaryExtension {

    @Test func testCaseInsensitive() async throws {
        var dict: [String: String] = ["Key": "Value"]
        #expect(dict["KEY"] == nil)
        #expect(dict["Key"] == "Value")
        #expect(dict["key"] == nil)
        #expect(dict[caseInsensitive: "KEY"] == "Value")
        #expect(dict[caseInsensitive: "Key"] == "Value")
        #expect(dict[caseInsensitive: "key"] == "Value")
        
        dict["key"] = "VALUE"
        dict.removeValue(forKey: "Key")
        #expect(dict["KEY"] == nil)
        #expect(dict["Key"] == nil)
        #expect(dict["key"] == "VALUE")
        #expect(dict[caseInsensitive: "KEY"] == "VALUE")
        #expect(dict[caseInsensitive: "Key"] == "VALUE")
        #expect(dict[caseInsensitive: "key"] == "VALUE")
    }

}
