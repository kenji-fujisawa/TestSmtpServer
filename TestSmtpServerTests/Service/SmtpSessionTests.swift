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
        let mailRepo = FakeMailRepository()
        let userRepo = FakeUserRepository()
        let dependency = SmtpDependencies(mailRepo, userRepo)
        let session = SmtpSession(dependency)
        let actions = session.onConnect()
        #expect(actions.count == 1)
        #expect(actions[0] == .write("220 Service ready\r\n"))
    }
    
    @Test func testHandle() async throws {
        let mailRepo = FakeMailRepository()
        let userRepo = FakeUserRepository()
        let dependency = SmtpDependencies(mailRepo, userRepo)
        let session = SmtpSession(dependency)
        
        var msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 AUTH PLAIN\r\n"))
        
        userRepo.name = "test"
        userRepo.password = "1234"
        
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
        
        msg = "from: from<from@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = "to: to1<to1@test.com>, to2<to2@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = "cc: cc<cc@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = "date: Fri, 26 Jun 2026 14:20:30 +0900\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = "subject: test subject\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = "\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
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
        
        msg = "RCPT TO:<ccc@test.jp> NOTIFY=SUCCESS,DELAY\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "DATA\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("354 Start mail input; end with <CRLF>.<CRLF>\r\n"))
        
        msg = "\r\n\r\nMAIL\r\n".data(using: .utf8) ?? Data()
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
        
        let mails = try mailRepo.getMails()
        #expect(mails.count == 2)
        #expect(mails[0].mail == "FROM:<aaa@test.com>")
        #expect(mails[0].rcpt == ["TO:<bbb@test.com>"])
        #expect(mails[0].data == """
            from: from<from@test.com>\r\n\
            to: to1<to1@test.com>, to2<to2@test.com>\r\n\
            cc: cc<cc@test.com>\r\n\
            date: Fri, 26 Jun 2026 14:20:30 +0900\r\n\
            subject: test subject\r\n\
            \r\n\
            aaa\r\n\
            bbb\r\n
            """)
        #expect(mails[0].from?.name == "from")
        #expect(mails[0].from?.address == "from@test.com")
        #expect(mails[0].to.count == 2)
        #expect(mails[0].to[0].name == "to1")
        #expect(mails[0].to[0].address == "to1@test.com")
        #expect(mails[0].to[1].name == "to2")
        #expect(mails[0].to[1].address == "to2@test.com")
        #expect(mails[0].cc.count == 1)
        #expect(mails[0].cc[0].name == "cc")
        #expect(mails[0].cc[0].address == "cc@test.com")
        #expect(mails[0].subject == "test subject")
        #expect(mails[0].body == "aaa\r\nbbb\r\n")
        #expect(mails[0].sent?.equals("2026-06-26 14:20:30") == true)
        #expect(mails[0].received?.equals(.now) == true)
        #expect(mails[1].mail == "FROM:<aaa@test.jp>")
        #expect(mails[1].rcpt == ["TO:<bbb@test.jp>", "TO:<ccc@test.jp> NOTIFY=SUCCESS,DELAY"])
        #expect(mails[1].data == """
            \r\n\
            \r\n\
            MAIL\r\n\
            DATA\r\n\
            .\r\n
            """)
        #expect(mails[1].from == nil)
        #expect(mails[1].to.count == 0)
        #expect(mails[1].cc.count == 0)
        #expect(mails[1].subject == "")
        #expect(mails[1].body == "MAIL\r\nDATA\r\n.\r\n")
        #expect(mails[1].sent == nil)
        #expect(mails[1].received?.equals(.now) == true)
    }
    
    @Test func testHandle_notAuthorized() async throws {
        let mailRepo = FakeMailRepository()
        let userRepo = FakeUserRepository()
        let dependency = SmtpDependencies(mailRepo, userRepo)
        let session = SmtpSession(dependency)
        
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
        
        let mails = try mailRepo.getMails()
        #expect(mails.count == 0)
    }
    
    @Test func testHandle_authWithoutTLS() async throws {
        let mailRepo = FakeMailRepository()
        let userRepo = FakeUserRepository()
        let dependency = SmtpDependencies(mailRepo, userRepo)
        let session = SmtpSession(dependency)
        
        var msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 STARTTLS\r\n"))
        
        msg = "AUTH PLAIN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("538 Encryption required for requested authentication mechanism\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        let mails = try mailRepo.getMails()
        #expect(mails.count == 0)
    }
    
    @Test func testHandle_failAuthenticate() async throws {
        let mailRepo = FakeMailRepository()
        let userRepo = FakeUserRepository()
        let dependency = SmtpDependencies(mailRepo, userRepo)
        let session = SmtpSession(dependency)
        
        var msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 AUTH PLAIN\r\n"))
        
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
        
        let mails = try mailRepo.getMails()
        #expect(mails.count == 0)
    }
    
    @Test func testHandle_authWithoutParam() async throws {
        let mailRepo = FakeMailRepository()
        let userRepo = FakeUserRepository()
        let dependency = SmtpDependencies(mailRepo, userRepo)
        let session = SmtpSession(dependency)
        
        var msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 AUTH PLAIN\r\n"))
        
        msg = "AUTH PLAIN\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("334 \r\n"))
        
        msg = "\0test\01234\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("501 Syntax error in parameters or arguments\r\n"))
        
        userRepo.name = "test"
        userRepo.password = "1234"
        
        msg = "dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("235 Authentication successful\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        let mails = try mailRepo.getMails()
        #expect(mails.count == 0)
    }
    
    @Test func testHandle_badSequence() async throws {
        let mailRepo = FakeMailRepository()
        let userRepo = FakeUserRepository()
        let dependency = SmtpDependencies(mailRepo, userRepo)
        let session = SmtpSession(dependency)
        
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
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 AUTH PLAIN\r\n"))
        
        userRepo.name = "test"
        userRepo.password = "1234"
        
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
        
        let mails = try mailRepo.getMails()
        #expect(mails.count == 0)
    }
    
    @Test func testHandle_invalidMailAddres() async throws {
        let mailRepo = FakeMailRepository()
        let userRepo = FakeUserRepository()
        let dependency = SmtpDependencies(mailRepo, userRepo)
        let session = SmtpSession(dependency)
        
        var msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 AUTH PLAIN\r\n"))
        
        userRepo.name = "test"
        userRepo.password = "1234"
        
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
        
        msg = "RCPT TO:<Postmaster>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "RCPT TO:<Postmaster@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250 OK\r\n"))
        
        msg = "QUIT\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("221 Service closing transmission channel\r\n"))
        #expect(actions[1] == .close)
        
        let mails = try mailRepo.getMails()
        #expect(mails.count == 0)
    }
    
    @Test func testHandleBuffer() async throws {
        let mailRepo = FakeMailRepository()
        let userRepo = FakeUserRepository()
        let dependency = SmtpDependencies(mailRepo, userRepo)
        let session = SmtpSession(dependency)
        
        var msg = "EHLO".data(using: .utf8) ?? Data()
        var actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = " ".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 0)
        
        msg = "localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 STARTTLS\r\n"))
        
        msg = "STARTTLS\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("220 Ready to start TLS\r\n"))
        #expect(actions[1] == .startTLS)
        
        session.onSwitchedToSSL()
        
        msg = "EHLO localhost\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("250-localhost HELLO\r\n250 AUTH PLAIN\r\n"))
        
        userRepo.name = "test"
        userRepo.password = "1234"
        
        msg = "AUTH PLAIN dGVzdAB0ZXN0ADEyMzQ=\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 1)
        #expect(actions[0] == .write("235 Authentication successful\r\n"))
        
        msg = "MAIL FROM:<aaa@test.com>\r\nRCPT TO:<bbb@test.com>\r\n".data(using: .utf8) ?? Data()
        actions = await session.handle(msg)
        #expect(actions.count == 2)
        #expect(actions[0] == .write("250 OK\r\n"))
        #expect(actions[1] == .write("250 OK\r\n"))
        
        msg = "DATA\r\n\r\n\r\naaa\r\n".data(using: .utf8) ?? Data()
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
        
        let mails = try mailRepo.getMails()
        #expect(mails.count == 1)
        #expect(mails[0].mail == "FROM:<aaa@test.com>")
        #expect(mails[0].rcpt == ["TO:<bbb@test.com>"])
        #expect(mails[0].data == """
            \r\n\
            \r\n\
            aaa\r\n\
            bbb\r\n
            """)
        #expect(mails[0].from == nil)
        #expect(mails[0].to.count == 0)
        #expect(mails[0].cc.count == 0)
        #expect(mails[0].subject == "")
        #expect(mails[0].body == "aaa\r\nbbb\r\n")
        #expect(mails[0].sent == nil)
        #expect(mails[0].received?.equals(.now) == true)
    }
    
    class FakeMailRepository: MailRepository {
        func getMailsStream() throws -> AsyncThrowingStream<[Mail], any Error> { AsyncThrowingStream { _ in } }
        
        private var mails: [Mail] = []
        func getMails() throws -> [Mail] {
            mails
        }
        
        func add(_ mail: Mail) throws {
            mails.append(mail)
        }
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

private extension Date {
    func equals(_ date: Date) -> Bool {
        abs(self.distance(to: date)) < 1
    }
    
    func equals(_ text: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = formatter.date(from: text) else { return false }
        return self.equals(date)
    }
}
