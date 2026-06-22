//
//  SmtpSession.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/16.
//

import Foundation

class SmtpSession: Session {
    typealias Dependency = UserRepository
    
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
        var from: String = ""
        var to: [String] = []
        var body: String = ""
        
        mutating func clear() {
            from = ""
            to = []
            body = ""
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
    
    private let userRepository: UserRepository
    private var state: State = .initial
    private var response = Response()
    private var buffer = Data()
    private var mail = Mail()
    private(set) var receivedMails: [Mail] = []
    private var ssl = false
    private var authorized = false
    
    required init(_ dependency: UserRepository) {
        self.userRepository = dependency
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
            handleDataContent(line)
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
        
        response.code = 250
        response.args = ["OK"]
        state = .mail
        mail.from = address
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
        guard isValidMailAddress(address) else {
            response.code = 550
            response.args = ["Invalid mail address"]
            return
        }
        
        response.code = 250
        response.args = ["OK"]
        state = .rcpt
        mail.to.append(address)
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
    
    private func handleDataContent(_ line: String) {
        if line == "." {
            response.code = 250
            response.args = ["OK"]
            state = .ready
            receivedMails.append(mail)
            return
        }
        
        var line = line
        if line.starts(with: "..") {
            line.removeFirst()
        }
        mail.body.append(line + "\r\n")
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
