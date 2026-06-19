//
//  SmtpSessionTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/16.
//

import Foundation
import Testing

@testable import TestSmtpServer

struct SmtpSessionTests {

    @Test func testResponse() async throws {
        var res = SmtpSession.Response()
        #expect(res.toString() == "")
        
        res.code = 250
        res.args = []
        #expect(res.toString() == "250 \r\n")
        
        res.args = ["OK"]
        #expect(res.toString() == "250 OK\r\n")
        
        res.args = ["aaa", "bbb", "ccc"]
        #expect(res.toString() == "250-aaa\r\n250-bbb\r\n250 ccc\r\n")
        
        res.clear()
        #expect(res.code == 0)
        #expect(res.args.isEmpty)
    }
    
    @Test func testOnConnect() async throws {
        let repository = FakeUserRepository()
        let session = SmtpSession(repository)
        let actions = session.onConnect()
        #expect(actions.count == 1)
        #expect(actions[0] == .write("220 Service ready\r\n"))
    }
    
    @Test func testHandle() async throws {
        let repository = FakeUserRepository()
        let session = SmtpSession(repository)
        
        var msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 AUTH PLAIN\r\n"))
        
        repository.name = "test"
        repository.password = "1234"
        
        msg = "AUTH PLAIN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("235 Authentication successful\r\n"))
        
        msg = "MAIL FROM:<aaa@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "RCPT TO:<bbb@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "DATA\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("354 Start mail input; end with <CRLF>.<CRLF>\r\n"))
        
        msg = "aaa\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = "bbb\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = ".\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "MAIL FROM:<aaa@test.jp>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "RCPT TO:<bbb@test.jp>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "RCPT TO:<ccc@test.jp>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "DATA\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("354 Start mail input; end with <CRLF>.<CRLF>\r\n"))
        
        msg = "MAIL\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = "DATA\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = "..\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = ".\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        #expect(session.receivedMails.count == 2)
        #expect(session.receivedMails[0].from == "aaa@test.com")
        #expect(session.receivedMails[0].to.count == 1)
        #expect(session.receivedMails[0].to[0] == "bbb@test.com")
        #expect(session.receivedMails[0].body == "aaa\r\nbbb\r\n")
        #expect(session.receivedMails[1].from == "aaa@test.jp")
        #expect(session.receivedMails[1].to.count == 2)
        #expect(session.receivedMails[1].to[0] == "bbb@test.jp")
        #expect(session.receivedMails[1].to[1] == "ccc@test.jp")
        #expect(session.receivedMails[1].body == "MAIL\r\nDATA\r\n.\r\n")
    }
    
    @Test func testHandle_notAuthorized() async throws {
        let repository = FakeUserRepository()
        let session = SmtpSession(repository)
        
        var msg = "HELO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "MAIL FROM:<aaa@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("530 Authentication required\r\n"))
        
        msg = "RCPT TO:<bbb@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("503 Bad sequence of commands\r\n"))
        
        msg = "DATA\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("503 Bad sequence of commands\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        #expect(session.receivedMails.count == 0)
    }
    
    @Test func testHandle_authWithoutTLS() async throws {
        let repository = FakeUserRepository()
        let session = SmtpSession(repository)
        
        var msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 STARTTLS\r\n"))
        
        msg = "AUTH PLAIN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("538 Encryption required for requested authentication mechanism\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        #expect(session.receivedMails.count == 0)
    }
    
    @Test func testHandle_failAuthenticate() async throws {
        let repository = FakeUserRepository()
        let session = SmtpSession(repository)
        
        var msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 AUTH PLAIN\r\n"))
        
        msg = "AUTH *\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("501 Syntax error in parameters or arguments\r\n"))
        
        msg = "AUTH PLAIN \0test\01234\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("501 Syntax error in parameters or arguments\r\n"))
        
        msg = "AUTH PLAIN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("535 Authentication credentials invalid\r\n"))
        
        msg = "AUTH PLAN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("504 Command parameter not implemented\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        #expect(session.receivedMails.count == 0)
    }
    
    @Test func testHandle_authWithoutParam() async throws {
        let repository = FakeUserRepository()
        let session = SmtpSession(repository)
        
        var msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 AUTH PLAIN\r\n"))
        
        msg = "AUTH PLAIN\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("334 \r\n"))
        
        msg = "\0test\01234\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("501 Syntax error in parameters or arguments\r\n"))
        
        repository.name = "test"
        repository.password = "1234"
        
        msg = "dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("235 Authentication successful\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        #expect(session.receivedMails.count == 0)
    }
    
    @Test func testHandle_badSequence() async throws {
        let repository = FakeUserRepository()
        let session = SmtpSession(repository)
        
        var msg = "AUTH PLAIN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("503 Bad sequence of commands\r\n"))
        
        msg = "MAIL FROM:<aaa@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("503 Bad sequence of commands\r\n"))
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 AUTH PLAIN\r\n"))
        
        repository.name = "test"
        repository.password = "1234"
        
        msg = "AUTH PLAIN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("235 Authentication successful\r\n"))
        
        msg = "AUTH PLAIN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("503 Bad sequence of commands\r\n"))
        
        msg = "MAIL FROM:<aaa@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "MAIL FROM:<aaa@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("503 Bad sequence of commands\r\n"))
        
        msg = "DATA\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("503 Bad sequence of commands\r\n"))
        
        msg = "RCPT TO:<bbb@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "RSET\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "DATA\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("503 Bad sequence of commands\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        #expect(session.receivedMails.count == 0)
    }
    
    @Test func testHandle_invalidMailAddres() async throws {
        let repository = FakeUserRepository()
        let session = SmtpSession(repository)
        
        var msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 AUTH PLAIN\r\n"))
        
        repository.name = "test"
        repository.password = "1234"
        
        msg = "AUTH PLAIN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("235 Authentication successful\r\n"))
        
        msg = "MAIL FROM:\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("501 Syntax error in parameters or arguments\r\n"))
        
        msg = "MAIL FROM:<>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("550 Invalid mail address\r\n"))
        
        msg = "MAIL FROM:<test>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("550 Invalid mail address\r\n"))
        
        msg = "MAIL FROM:<aaa@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "RCPT TO:\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("501 Syntax error in parameters or arguments\r\n"))
        
        msg = "RCPT TO:<>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("550 Invalid mail address\r\n"))
        
        msg = "RCPT TO:<test>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("550 Invalid mail address\r\n"))
        
        msg = "RCPT TO:<bbb@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        #expect(session.receivedMails.count == 0)
    }
    
    @Test func testHandleBuffer() async throws {
        let repository = FakeUserRepository()
        let session = SmtpSession(repository)
        
        var msg = "EHLO".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = " ".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = "localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 AUTH PLAIN\r\n"))
        
        repository.name = "test"
        repository.password = "1234"
        
        msg = "AUTH PLAIN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("235 Authentication successful\r\n"))
        
        msg = "MAIL FROM:<aaa@test.com>\r\nRCPT TO:<bbb@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("250 OK\r\n"))
        #expect(actions[1] == .write("250 OK\r\n"))
        
        msg = "DATA\r\naaa\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("354 Start mail input; end with <CRLF>.<CRLF>\r\n"))
        
        msg = "bbb\r\n.\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        #expect(session.receivedMails.count == 1)
        #expect(session.receivedMails[0].from == "aaa@test.com")
        #expect(session.receivedMails[0].to.count == 1)
        #expect(session.receivedMails[0].to[0] == "bbb@test.com")
        #expect(session.receivedMails[0].body == "aaa\r\nbbb\r\n")
    }
    
    class FakeUserRepository: UserRepository {
        func getUsers() throws -> [User] { [] }
        func register(name: String, password: String) async throws {}
        func unregister(name: String) throws {}
        
        var name: String? = nil
        var password: String? = nil
        func authenticate(name: String, password: String) async throws -> Bool {
            self.name == name && self.password == password
        }
    }
}
