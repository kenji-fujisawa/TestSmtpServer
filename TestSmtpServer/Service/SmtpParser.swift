//
//  SmtpParser.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/30.
//

import Foundation
import RegexBuilder

protocol SmtpParser {
    func parseData(_ data: String) -> (header: [String: [String]], body: String)
    func removeCommentAndQuote(_ value: String) -> String
    func parseAddressList(_ addressList: String) -> [(groupName: String, group: [(name: String, address: String)])]
    func parseDateTime(_ value: String) -> Date?
    func parseQuotedPrintable(_ value: String, encoding: String.Encoding) -> String?
    func parseMimeHeader(_ value: String) -> String
}

class DefaultSmtpParser: SmtpParser {
    func parseData(_ data: String) -> (header: [String: [String]], body: String) {
        let (header, body) = splitData(data)
        return (parseHeader(unfold(header)), body)
    }
    
    private func splitData(_ data: String) -> (String, String) {
        let separator = "\r\n\r\n"
        let parts = data.split(separator: separator, maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return (data, "") }
        let header = String(parts[0] + "\r\n")
        let body = String(parts[1])
        return (header, body)
    }
    
    private func unfold(_ header: String) -> String {
        let regex = Regex {
            "\r\n"
            Lookahead {
                OneOrMore(.horizontalWhitespace)
            }
        }
        return header.replacing(regex, with: "")
    }
    
    private func parseHeader(_ header: String) -> [String: [String]] {
        var results: [String: [String]] = [:]
        
        let lines = header.split(separator: "\r\n")
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0].uppercased())
            let value = trimLeadingSpace(String(parts[1]))
            results[key, default: []].append(value)
        }
        
        return results
    }
    
    private func trimLeadingSpace(_ value: String) -> String {
        let regex = Regex {
            Anchor.startOfSubject
            OneOrMore(.horizontalWhitespace)
        }
        return value.replacing(regex, with: "")
    }
    
    func removeCommentAndQuote(_ value: String) -> String {
        var result = String()
        result.reserveCapacity(value.count)
        
        var depth = 0
        var escaped = false
        var quoted = false
        for char in value {
            if escaped {
                if depth == 0 { result.append(char) }
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if quoted && char == "\"" {
                quoted = false
            } else if quoted {
                result.append(char)
            } else if depth > 0 && char == ")" {
                depth -= 1
            } else if depth > 0 && char == "(" {
                depth += 1
            } else if depth > 0 {
                continue
            } else if char == "\"" {
                quoted = true
            } else if char == "(" {
                depth = 1
            } else {
                result.append(char)
            }
        }
        
        return result
    }
    
    func parseAddressList(_ addressList: String) -> [(groupName: String, group: [(name: String, address: String)])] {
        var result: [(String, [(String, String)])] = []
        
        let groups = splitAddressGroup(addressList)
        for (groupName, groupList) in groups {
            let namedAddressList = groupList.map { parseAddress($0) }
            result.append((groupName, namedAddressList))
        }
        
        return result
    }
    
    private func splitAddressGroup(_ addressList: String) -> [(String, [String])] {
        var groups: [(String, [String])] = []
        var group: [String] = []
        var buf = String()
        var name = ""
        var grouped = false
        var escaped = false
        var quoted = false
        var depth = 0
        for char in addressList {
            if escaped {
                buf.append(char)
                escaped = false
            } else if char == "\\" {
                buf.append(char)
                escaped = true
            } else if quoted && char == "\"" {
                buf.append(char)
                quoted = false
            } else if quoted {
                buf.append(char)
            } else if depth > 0 && char == ")" {
                buf.append(char)
                depth -= 1
            } else if depth > 0 && char == "(" {
                buf.append(char)
                depth += 1
            } else if depth > 0 {
                buf.append(char)
            } else if char == "\"" {
                buf.append(char)
                quoted = true
            } else if char == "(" {
                buf.append(char)
                depth = 1
            } else if char == ":" {
                if !group.isEmpty {
                    groups.append((name, group))
                    group.removeAll()
                }
                name = buf.trimmingCharacters(in: .whitespaces)
                buf = String()
                grouped = true
            } else if char == ";" {
                let address = buf.trimmingCharacters(in: .whitespaces)
                if !address.isEmpty { group.append(address) }
                groups.append((name, group))
                group.removeAll()
                name = ""
                buf = String()
                grouped = false
            } else if char == "," {
                let address = buf.trimmingCharacters(in: .whitespaces)
                if !address.isEmpty { group.append(address) }
                if !grouped && !group.isEmpty {
                    groups.append((name, group))
                    group.removeAll()
                }
                buf = String()
            } else {
                buf.append(char)
            }
        }
        
        let address = buf.trimmingCharacters(in: .whitespaces)
        if !address.isEmpty {
            group.append(address)
            groups.append((name, group))
        }
        
        return groups
    }
    
    private func parseAddress(_ namedAddress: String) -> (String, String) {
        guard var begin = namedAddress.firstIndex(of: "<"),
              let end = namedAddress.firstIndex(of: ">") else {
            let address = namedAddress.trimmingCharacters(in: .whitespaces)
            return ("", address)
        }
        
        let name = namedAddress[namedAddress.startIndex..<begin].trimmingCharacters(in: .whitespaces)
        
        begin = namedAddress.index(begin, offsetBy: 1)
        let address = namedAddress[begin..<end].trimmingCharacters(in: .whitespaces)
        
        return (name, address)
    }
    
    func parseDateTime(_ value: String) -> Date? {
        let value = value
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        let candidates = [
            "EEE, d MMM yyyy HH:mm:ss Z",
            "EEE, d MMM yyyy HH:mm Z",
            "d MMM yyyy HH:mm:ss Z",
            "d MMM yyyy HH:mm Z"
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        for candidate in candidates {
            formatter.dateFormat = candidate
            if let date = formatter.date(from: value) {
                return date
            }
        }
        
        return nil
    }
    
    func parseQuotedPrintable(_ value: String, encoding: String.Encoding) -> String? {
        let value = value
            .replacingOccurrences(of: "=\r\n", with: "")
            .replacingOccurrences(of: "=\n", with: "")
        let bytes = Array(value.utf8)
        var data = Data()
        var i = 0
        while i < bytes.count {
            if bytes[i] == 61 {
                if i + 2 < bytes.count {
                    let hex = String(bytes: [bytes[i + 1], bytes[i + 2]], encoding: .ascii) ?? ""
                    if let byte = UInt8(hex, radix: 16) {
                        data.append(byte)
                        i += 3
                        continue
                    }
                }
            }
            
            data.append(bytes[i])
            i += 1
        }
        
        return String(data: data, encoding: encoding)
    }
    
    func parseMimeHeader(_ value: String) -> String {
        let pattern = "=\\?([^?]+)\\?([BbQq])\\?([^?]*)\\?="
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return value }
        
        let value = value.replacingOccurrences(of: "\\?=\\s+=\\?", with: "?==?", options: .regularExpression)
        
        var result = value
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        let matches = regex.matches(in: value, range: range)
        for match in matches.reversed() {
            guard match.numberOfRanges == 4,
                  let charsetRange = Range(match.range(at: 1), in: value),
                  let encodingRange = Range(match.range(at: 2), in: value),
                  let dataRange = Range(match.range(at: 3), in: value) else {
                      continue
                  }
            
            let charset = value[charsetRange].uppercased()
            let encoding = value[encodingRange].uppercased()
            let encoded = value[dataRange]
            
            let stringEncoding: String.Encoding = if charset.contains("ISO-2022-JP") {
                String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.ISO_2022_JP.rawValue)))
            } else if charset.contains("SHIFT_JIS") || charset.contains("SJIS") {
                .shiftJIS
            } else if charset.contains("EUC-JP") {
                .japaneseEUC
            } else {
                .utf8
            }
            
            var decoded: String? = nil
            if encoding == "B" {
                if let data = Data(base64Encoded: String(encoded)) {
                    decoded = String(data: data, encoding: stringEncoding)
                }
            } else if encoding == "Q" {
                let encoded = encoded.replacingOccurrences(of: "_", with: " ")
                decoded = parseQuotedPrintable(encoded, encoding: stringEncoding)
            }
            
            if let decoded = decoded,
               let range = Range(match.range(at: 0), in: result) {
                result.replaceSubrange(range, with: decoded)
            }
        }
        
        return result
    }
}
