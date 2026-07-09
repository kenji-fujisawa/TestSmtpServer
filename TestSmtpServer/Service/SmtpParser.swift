//
//  SmtpParser.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/30.
//

import Foundation
import RegexBuilder

struct MimeBody {
    enum ContentType {
        case unknown
        case text
        case data
        case mixed
        case alternative
        case related
    }
    
    var type: ContentType = .unknown
    var contentType: String = ""
    var charset: String = ""
    var body: String = ""
    var filename: String = ""
    var data: Data? = nil
    var children: [MimeBody] = []
    
    var flatten: [MimeBody] {
        type == .mixed || type == .alternative || type == .related
        ? children.flatMap { $0.flatten }
        : [self]
    }
}

protocol SmtpParser {
    func parseData(_ data: String) -> (header: [String: [String]], body: String)
    func removeCommentAndQuote(_ value: String) -> String
    func parseAddressList(_ addressList: String) -> [(groupName: String, group: [(name: String, address: String)])]
    func parseDateTime(_ value: String) -> Date?
    func parseQuotedPrintable(_ value: String, encoding: String.Encoding) -> String?
    func parseMimeHeader(_ value: String) -> String
    func parseMimeBody(header: [String: [String]], body: String) -> MimeBody
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
            
            let charset = value[charsetRange]
            let encoding = value[encodingRange].uppercased()
            let encoded = value[dataRange]
            let stringEncoding = toEncoding(String(charset))
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
    
    private func toEncoding(_ charset: String) -> String.Encoding {
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
        let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
        return String.Encoding(rawValue: nsEncoding)
    }
    
    func parseMimeBody(header: [String: [String]], body: String) -> MimeBody {
        let contentType = header["CONTENT-TYPE"]?.first ?? "text/plain; charset=us-ascii"
        let (contentTypeValue, contentTypeParams) = parseContentHeader(contentType)
        let types = contentTypeValue.split(separator: "/")
        guard types.count == 2 else { return MimeBody() }
        let type = types[0].trimmingCharacters(in: .whitespaces).uppercased()
        let subtype = types[1].trimmingCharacters(in: .whitespaces).uppercased()
        
        if type == "TEXT" {
            let charset = contentTypeParams["CHARSET"] ?? ""
            let encoding = header["CONTENT-TRANSFER-ENCODING"]?.first?.trimmingCharacters(in: .whitespaces).uppercased() ?? "7BIT"
            let stringEncoding = toEncoding(charset)
            var decoded: String? = nil
            if encoding == "BASE64" {
                let body = body.replacingOccurrences(of: #"[ \t\r\n]"#, with: "", options: .regularExpression)
                if let data = Data(base64Encoded: body) {
                    decoded = String(data: data, encoding: stringEncoding)
                }
            } else if encoding == "QUOTED-PRINTABLE" {
                decoded = parseQuotedPrintable(body, encoding: stringEncoding)
            } else if encoding == "7BIT" || encoding == "8BIT" {
                if let data = body.data(using: .utf8) {
                    decoded = String(data: data, encoding: stringEncoding)
                }
            }
            
            return MimeBody(type: .text, contentType: contentTypeValue, charset: charset, body: decoded ?? "")
        } else if type == "MULTIPART" {
            guard let boundary = contentTypeParams["BOUNDARY"] else { return MimeBody() }
            
            var children: [MimeBody] = []
            let sections = splitSections(body, boundary: boundary)
            for section in sections {
                let (header, body) = splitData(section)
                let child = parseMimeBody(header: parseHeader(header), body: body)
                children.append(child)
            }
            
            if subtype == "MIXED" {
                return MimeBody(type: .mixed, contentType: contentTypeValue, children: children)
            } else if subtype == "ALTERNATIVE" {
                return MimeBody(type: .alternative, contentType: contentTypeValue, children: children)
            } else if subtype == "RELATED" {
                return MimeBody(type: .related, contentType: contentTypeValue, children: children)
            }
        } else {
            let charset = contentTypeParams["CHARSET"] ?? ""
            
            let disposition = header["CONTENT-DISPOSITION"]?.first ?? ""
            let (_, params) = parseContentHeader(disposition)
            var filename = ""
            if let val = params["FILENAME"] {
                filename = parseMimeHeader(val)
            } else if let val = contentTypeParams["NAME"] {
                filename = parseMimeHeader(val)
            }
            
            let encoding = header["CONTENT-TRANSFER-ENCODING"]?.first?.trimmingCharacters(in: .whitespaces).uppercased() ?? ""
            var data: Data? = nil
            if encoding == "BASE64" {
                let body = body.replacingOccurrences(of: #"[ \t\r\n]"#, with: "", options: .regularExpression)
                data = Data(base64Encoded: body)
            }
            
            return MimeBody(type: .data, contentType: contentTypeValue, charset: charset, filename: filename, data: data)
        }
        
        return MimeBody()
    }
    
    private func parseContentHeader(_ header: String) -> (value: String, params: [String: String]) {
        var parts: [String] = []
        var buf = String()
        var quoted = false
        var escaped = false
        for char in header {
            if escaped {
                buf.append(char)
                escaped = false
            } else if quoted && char == "\\" {
                escaped = true
            } else if quoted && char == "\"" {
                quoted = false
            } else if char == "\"" {
                quoted = true
            } else if !quoted && char == " " {
                continue
            } else if !quoted && char == ";" {
                if !buf.isEmpty { parts.append(buf) }
                buf = String()
            } else {
                buf.append(char)
            }
        }
        
        if !buf.isEmpty {
            parts.append(buf)
        }
        
        guard parts.count >= 1 else { return ("", [:]) }
        
        let value = parts[0].uppercased()
        var params: [String: String] = [:]
        for part in parts.dropFirst() {
            let parts = part.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].uppercased()
            params[key] = String(parts[1])
        }
        
        return (value, mergeAndDecodeParams(params))
    }
    
    private func mergeAndDecodeParams(_ params: [String: String]) -> [String: String] {
        let pattern = "([^\\*]*)\\*([0-9]+)(\\*?)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return params }
        
        var results: [String: String] = [:]
        for (key, value) in params {
            let range = NSRange(key.startIndex..<key.endIndex, in: key)
            let matches = regex.matches(in: key, range: range)
            guard matches.count == 1,
                  let match = matches.first,
                  match.numberOfRanges >= 3,
                  let keyNameRange = Range(match.range(at: 1), in: key),
                  let indexRange = Range(match.range(at: 2), in: key),
                  var index = Int(key[indexRange]) else {
                if key.last == "*" {
                    results[String(key.dropLast())] = decodeCharsetAndLanguageEncoding(value)
                } else {
                    results[key] = value
                }
                continue
            }
            guard index == 0 else { continue }
            
            let keyName = key[keyNameRange]
            let encoded = match.numberOfRanges >= 4
            var value = value
            while true {
                index += 1
                let key1 = "\(keyName)*\(index)*"
                let key2 = "\(keyName)*\(index)"
                guard let continuation = params[key1] ?? params[key2] else { break }
                value += continuation
            }
            
            if encoded {
                value = decodeCharsetAndLanguageEncoding(value)
            }
            
            results[String(keyName)] = value
        }
        
        return results
    }
    
    private func decodeCharsetAndLanguageEncoding(_ value: String) -> String {
        let parts = value.split(separator: "'")
        guard parts.count >= 2,
              let encodedFilename = parts.last else {
            return value.removingPercentEncoding ?? ""
        }
        
        let charset = String(parts[0])
        let stringEncoding = toEncoding(charset)
        return decodePercentEncoding(String(encodedFilename), encoding: stringEncoding)
    }
    
    private func decodePercentEncoding(_ value: String, encoding: String.Encoding) -> String {
        let components = value.components(separatedBy: "%")
        
        var data = Data()
        
        if let first = components.first,
           !first.isEmpty,
           let ascii = first.data(using: .ascii) {
            data.append(ascii)
        }
        
        for part in components.dropFirst() {
            if part.isEmpty { continue }
            
            let hex = String(part.prefix(2))
            let remain = String(part.dropFirst(2))
            if let byte = UInt8(hex, radix: 16) {
                data.append(byte)
            }
            
            if !remain.isEmpty,
               let ascii = remain.data(using: .ascii) {
                data.append(ascii)
            }
        }
        
        return String(data: data, encoding: encoding) ?? ""
    }
    
    private func splitSections(_ body: String, boundary: String) -> [String] {
        let lines = body.split(separator: "\r\n", omittingEmptySubsequences: false)
        var sections: [String] = []
        var section = String()
        var inSection = false
        for line in lines {
            if line == "--\(boundary)--" {
                if !section.isEmpty { sections.append(section) }
                break
            } else if !inSection && line != "--\(boundary)" {
                continue
            } else if !inSection && line == "--\(boundary)" {
                inSection = true
            } else if line == "--\(boundary)" {
                sections.append(section)
                section = String()
            } else {
                section.append(line + "\r\n")
            }
        }
        
        return sections
    }
}
