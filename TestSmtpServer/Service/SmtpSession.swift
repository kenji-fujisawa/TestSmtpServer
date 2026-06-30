//
//  SmtpSession.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/16.
//

import Foundation
import RegexBuilder

struct SmtpDependencies {
    let mailRepository: MailRepository
    let userRepository: UserRepository
    
    init(_ mailRepository: MailRepository, _ userRepository: UserRepository) {
        self.mailRepository = mailRepository
        self.userRepository = userRepository
    }
}

class SmtpSession: Session {
    typealias Dependency = SmtpDependencies
    
    private enum State {
        case initial
        case ready
        case startTLS
        case auth
        case mail
        case rcpt
        case data
        case quit
    }
    
    struct Mail {
        var mail: String = ""
        var rcpt: [String] = []
        var data: String = ""
        
        mutating func clear() {
            mail = ""
            rcpt = []
            data = ""
        }
    }
    
    struct Response {
        var code: Int = 0
        var args: [String] = []
        
        func toString() -> String {
            if args.isEmpty {
                return code == 0 ? "" : "\(code) \r\n"
            }
            
            return args.enumerated()
                .map { (idx, elm) in idx == args.count - 1 ? "\(code) \(elm)\r\n" : "\(code)-\(elm)\r\n" }
                .joined()
        }
        
        mutating func clear() {
            code = 0
            args = []
        }
    }
    
    private static let bufferLimit = 4096 * 1000
    
    private let mailRepository: MailRepository
    private let userRepository: UserRepository
    private var state: State = .initial
    private var response = Response()
    private var buffer = Data()
    private var mail = Mail()
    private var ssl = false
    private var authorized = false
    
    required init(_ dependency: SmtpDependencies) {
        self.mailRepository = dependency.mailRepository
        self.userRepository = dependency.userRepository
    }
    
    func onConnect() -> [SessionAction] {
        let response = Response(code: 220, args: ["Service ready"])
        return [.write(response.toString())]
    }
    
    func onSwitchedToSSL() {
        state = .initial
        ssl = true
        authorized = false
        mail.clear()
    }
    
    func handle(_ chunk: Data) async -> [SessionAction] {
        guard let separator = "\r\n".data(using: .utf8) else { return [] }
        
        var actions: [SessionAction] = []
        
        buffer.append(chunk)
        while let range = buffer.range(of: separator) {
            let lineRange = 0..<(range.endIndex - separator.count)
            let lineData = buffer.subdata(in: lineRange)
            buffer.removeSubrange(0..<range.endIndex)
            if let line = String(data: lineData, encoding: .utf8) {
                response.clear()
                
                await handle(line)
                
                let response = self.response.toString()
                if !response.isEmpty {
                    actions.append(.write(response))
                }
                
                if state == .startTLS {
                    actions.append(.startTLS)
                } else if state == .quit {
                    actions.append(.close)
                }
            }
        }
        
        guard buffer.count <= SmtpSession.bufferLimit else {
            return [.close]
        }
        
        return actions
    }
    
    private func handle(_ line: String) async {
        if state == .auth {
            await handleAuthPlain(line)
            return
        }
        
        if state == .data {
            await handleDataContent(line)
            return
        }
        
        let commands = line.split(whereSeparator: \.isWhitespace)
        let command = commands.isEmpty ? "" : commands[0].uppercased()
        switch command {
        case "HELO":
            handleHELO(line)
        case "EHLO":
            handleEHLO(line)
        case "STARTTLS":
            handleStartTLS(line)
        case "AUTH":
            await handleAUTH(line)
        case "MAIL":
            handleMAIL(line)
        case "RCPT":
            handleRCPT(line)
        case "DATA":
            handleDATA(line)
        case "RSET":
            handleRSET(line)
        case "NOOP":
            handleNOOP(line)
        case "QUIT":
            handleQUIT(line)
        case "VRFY", "EXPN", "HELP":
            response.code = 502
            response.args = ["Command not implemented"]
        default:
            response.code = 500
            response.args = ["Command not recognized"]
        }
    }
    
    private func handleHELO(_ line: String) {
        response.code = 250
        response.args = ["OK"]
        state = .ready
        mail.clear()
    }
    
    private func handleEHLO(_ line: String) {
        if ssl {
            response.code = 250
            response.args = ["AUTH PLAIN"]
            state = .ready
            mail.clear()
        } else {
            response.code = 250
            response.args = ["STARTTLS"]
            state = .ready
            mail.clear()
        }
    }
    
    private func handleStartTLS(_ line: String) {
        response.code = 220
        response.args = ["Ready to start TLS"]
        state = .startTLS
    }
    
    private func handleAUTH(_ line: String) async {
        guard authorized == false,
              state == .ready else {
            response.code = 503
            response.args = ["Bad sequence of commands"]
            return
        }
        
        let args = line.split(whereSeparator: \.isWhitespace)
        guard args.count >= 2,
              args[1] != "*" else {
            response.code = 501
            response.args = ["Syntax error in parameters or arguments"]
            return
        }
        
        switch args[1] {
        case "PLAIN":
            guard ssl == true else {
                response.code = 538
                response.args = ["Encryption required for requested authentication mechanism"]
                return
            }
            
            if args.count == 2 {
                response.code = 334
                response.args = [""]
                state = .auth
                return
            }
            
            await handleAuthPlain(String(args[2]))
        default:
            response.code = 504
            response.args = ["Command parameter not implemented"]
        }
    }
    
    private func handleAuthPlain(_ base64Encoded: String) async {
        guard let decodedData = Data(base64Encoded: base64Encoded),
              let decodedString = String(data: decodedData, encoding: .utf8) else {
            response.code = 501
            response.args = ["Syntax error in parameters or arguments"]
            return
        }
        
        var userPass = decodedString.split(separator: "\0")
        guard userPass.count == 2 || userPass.count == 3 else {
            response.code = 501
            response.args = ["Syntax error in parameters or arguments"]
            return
        }
        
        do {
            if userPass.count == 3 {
                userPass.removeFirst()
            }
            
            let user = String(userPass[0])
            let pass = String(userPass[1])
            guard try await userRepository.authenticate(name: user, password: pass) else {
                response.code = 535
                response.args = ["Authentication credentials invalid"]
                return
            }
        } catch {
            await Logger.shared.log(error)
            response.code = 454
            response.args = ["Temporary authentication failure"]
            return
        }
        
        response.code = 235
        response.args = ["Authentication successful"]
        state = .ready
        authorized = true
    }
    
    private func handleMAIL(_ line: String) {
        guard state == .ready else {
            response.code = 503
            response.args = ["Bad sequence of commands"]
            return
        }
        
        guard authorized else {
            response.code = 530
            response.args = ["Authentication required"]
            return
        }
        
        guard var begin = line.firstIndex(of: "<"),
              let end = line.firstIndex(of: ">") else {
            response.code = 501
            response.args = ["Syntax error in parameters or arguments"]
            return
        }
        
        begin = line.index(begin, offsetBy: 1)
        let address = String(line[begin..<end])
        guard isValidMailAddress(address) else {
            response.code = 550
            response.args = ["Invalid mail address"]
            return
        }
        
        mail.clear()
        
        var index = line.firstIndex(of: " ") ?? line.startIndex
        index = line.index(index, offsetBy: 1)
        
        response.code = 250
        response.args = ["OK"]
        state = .mail
        mail.mail = String(line[index...])
    }
    
    private func handleRCPT(_ line: String) {
        guard state == .mail || state == .rcpt else {
            response.code = 503
            response.args = ["Bad sequence of commands"]
            return
        }
        
        guard authorized else {
            response.code = 530
            response.args = ["Authentication required"]
            return
        }
        
        guard var begin = line.firstIndex(of: "<"),
              let end = line.firstIndex(of: ">") else {
            response.code = 501
            response.args = ["Syntax error in parameters or arguments"]
            return
        }
        
        begin = line.index(begin, offsetBy: 1)
        let address = String(line[begin..<end])
        guard isValidMailAddress(address) || address.lowercased() == "postmaster" else {
            response.code = 550
            response.args = ["Invalid mail address"]
            return
        }
        
        var index = line.firstIndex(of: " ") ?? line.startIndex
        index = line.index(index, offsetBy: 1)
        
        response.code = 250
        response.args = ["OK"]
        state = .rcpt
        mail.rcpt.append(String(line[index...]))
    }
    
    private func handleDATA(_ line: String) {
        guard state == .rcpt else {
            response.code = 503
            response.args = ["Bad sequence of commands"]
            return
        }
        
        guard authorized else {
            response.code = 530
            response.args = ["Authentication required"]
            return
        }
        
        response.code = 354
        response.args = ["Start mail input; end with <CRLF>.<CRLF>"]
        state = .data
    }
    
    private func handleDataContent(_ line: String) async {
        if line == "." {
            let toAddress = { (name: String, address: String) in
                TestSmtpServer.Mail.Address(
                    name: SmtpParser.shared.parseMimeHeader(SmtpParser.shared.removeCommentAndQuote(name)),
                    address: SmtpParser.shared.removeCommentAndQuote(address)
                )
            }
            
            let (header, body) = SmtpParser.shared.parseData(mail.data)
            let from = SmtpParser.shared.parseAddressList(header["FROM"]?[0] ?? "")
                .flatMap { $0.group }
                .map { toAddress($0.name, $0.address) }
                .first
            let to = SmtpParser.shared.parseAddressList(header["TO"]?[0] ?? "")
                .flatMap { $0.group }
                .map { toAddress($0.name, $0.address) }
            let cc = SmtpParser.shared.parseAddressList(header["CC"]?[0] ?? "")
                .flatMap { $0.group }
                .map { toAddress($0.name, $0.address) }
            let subject = SmtpParser.shared.parseMimeHeader(SmtpParser.shared.removeCommentAndQuote(header["SUBJECT"]?[0] ?? ""))
            let sent = SmtpParser.shared.parseDateTime(SmtpParser.shared.removeCommentAndQuote(header["DATE"]?[0] ?? ""))
            
            do {
                let mail = TestSmtpServer.Mail(
                    mail: self.mail.mail,
                    rcpt: self.mail.rcpt,
                    data: self.mail.data,
                    from: from,
                    to: to,
                    cc: cc,
                    subject: subject,
                    body: body,
                    sent: sent,
                    received: .now
                )
                try mailRepository.add(mail)
            } catch {
                await Logger.shared.log(error)
                response.code = 451
                response.args = ["Requested action aborted: local error in processing"]
                return
            }
            
            response.code = 250
            response.args = ["OK"]
            state = .ready
            return
        }
        
        var line = line
        if line.starts(with: "..") {
            line.removeFirst()
        }
        mail.data.append(line + "\r\n")
    }
    
    private func handleRSET(_ line: String) {
        response.code = 250
        response.args = ["OK"]
        state = .ready
        mail.clear()
    }
    
    private func handleNOOP(_ line: String) {
        response.code = 250
        response.args = ["OK"]
    }
    
    private func handleQUIT(_ line: String) {
        response.code = 221
        response.args = ["Service closing transmission channel"]
        state = .quit
    }
    
    private func isValidMailAddress(_ address: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: address)
    }
}

class SmtpParser {
    static let shared = SmtpParser()
    
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
