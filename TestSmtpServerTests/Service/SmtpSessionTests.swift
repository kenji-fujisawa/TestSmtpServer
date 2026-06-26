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
    
    @Test func testParseData() async throws {
        let data =
            #"quoted_pair: aaa \a \b \c \( \) \" \\ bbb"# + "\r\n" +
            #"quoted_pair_in_comment: aaa (\a \b \c \( \) \" \\) bbb"# + "\r\n" +
            #"quoted_pair_in_quote: aaa "\a \b \c \( \) \" \\" bbb"# + "\r\n" +
            "folded: aaa" + "\r\n" +
            "   bbb ccc" + "\r\n" +
            "tab_folded: aaa" + "\r\n" +
            "\t \t bbb ccc" + "\r\n" +
            "folded_in_comment: aaa (bbb" + "\r\n" +
            "   ccc) ddd" + "\r\n" +
            #"folded_in_quote: aaa "bbb"# + "\r\n" +
            #"   ccc" ddd"# + "\r\n" +
            "nested_comment: aaa (bbb (ccc (()ddd))) eee" + "\r\n" +
            #"escaped_comment: aaa \(bbb\) (ccc \) ddd) eee"# + "\r\n" +
            #"quoted: aaa "bbb (ccc) \"ddd\" eee" fff"# + "\r\n" +
            #"quoted_in_comment: aaa (bbb "ccc" ddd) eee"# + "\r\n" +
            "no_space_with_separator:aaa bbb ccc" + "\r\n" +
            "multi_space_with_separator:   aaa bbb ccc" + "\r\n" +
            "tab_with_separator:\t\taaa bbb ccc" + "\r\n" +
            "trailing_space: aaa bbb ccc \t \t" + "\r\n" +
            "duplicated_field: aaa bbb" + "\r\n" +
            "duplicated_field: ccc ddd" + "\r\n" +
            "\r\n" +
            "\r\n" +
            "body" + "\r\n" +
            #"quoted_pair: aaa \a \b \c \( \) \" \\ bbb"# + "\r\n" +
            #"quoted_pair_in_comment: aaa (\a \b \c \( \) \" \\) bbb"# + "\r\n" +
            #"quoted_pair_in_quote: aaa "\a \b \c \( \) \" \\" bbb"# + "\r\n" +
            "folded: aaa" + "\r\n" +
            "   bbb ccc" + "\r\n" +
            "tab_folded: aaa" + "\r\n" +
            "\t \t bbb ccc" + "\r\n" +
            "folded_in_comment: aaa (bbb" + "\r\n" +
            "   ccc) ddd" + "\r\n" +
            #"folded_in_quote: aaa "bbb"# + "\r\n" +
            #"   ccc" ddd"# + "\r\n" +
            "nested_comment: aaa (bbb (ccc (()ddd))) eee" + "\r\n" +
            #"escaped_comment: aaa \(bbb\) (ccc \) ddd) eee"# + "\r\n" +
            #"quoted: aaa "bbb (ccc) \"ddd\" eee" fff"# + "\r\n" +
            #"quoted_in_comment: aaa (bbb "ccc" ddd) eee"# + "\r\n" +
            "no_space_with_separator:aaa bbb ccc" + "\r\n" +
            "multi_space_with_separator:   aaa bbb ccc" + "\r\n" +
            "tab_with_separator:\t\taaa bbb ccc" + "\r\n" +
            "trailing_space: aaa bbb ccc \t \t" + "\r\n" +
            "duplicated_field: aaa bbb" + "\r\n" +
            "duplicated_field: ccc ddd" + "\r\n" +
            "\r\n" +
            "end" + "\r\n"
        
        let parser = SmtpParser()
        let (header, body) = parser.parseData(data)
        
        #expect(header["QUOTED_PAIR"] == [#"aaa \a \b \c \( \) \" \\ bbb"#])
        #expect(header["QUOTED_PAIR_IN_COMMENT"] == [#"aaa (\a \b \c \( \) \" \\) bbb"#])
        #expect(header["QUOTED_PAIR_IN_QUOTE"] == [#"aaa "\a \b \c \( \) \" \\" bbb"#])
        #expect(header["FOLDED"] == ["aaa   bbb ccc"])
        #expect(header["TAB_FOLDED"] == ["aaa\t \t bbb ccc"])
        #expect(header["FOLDED_IN_COMMENT"] == ["aaa (bbb   ccc) ddd"])
        #expect(header["FOLDED_IN_QUOTE"] == [#"aaa "bbb   ccc" ddd"#])
        #expect(header["NESTED_COMMENT"] == ["aaa (bbb (ccc (()ddd))) eee"])
        #expect(header["ESCAPED_COMMENT"] == [#"aaa \(bbb\) (ccc \) ddd) eee"#])
        #expect(header["QUOTED"] == [#"aaa "bbb (ccc) \"ddd\" eee" fff"#])
        #expect(header["QUOTED_IN_COMMENT"] == [#"aaa (bbb "ccc" ddd) eee"#])
        #expect(header["NO_SPACE_WITH_SEPARATOR"] == ["aaa bbb ccc"])
        #expect(header["MULTI_SPACE_WITH_SEPARATOR"] == ["aaa bbb ccc"])
        #expect(header["TAB_WITH_SEPARATOR"] == ["aaa bbb ccc"])
        #expect(header["TRAILING_SPACE"] == ["aaa bbb ccc \t \t"])
        #expect(header["DUPLICATED_FIELD"] == ["aaa bbb", "ccc ddd"])
        
        let expect =
            "\r\n" +
            "body" + "\r\n" +
            #"quoted_pair: aaa \a \b \c \( \) \" \\ bbb"# + "\r\n" +
            #"quoted_pair_in_comment: aaa (\a \b \c \( \) \" \\) bbb"# + "\r\n" +
            #"quoted_pair_in_quote: aaa "\a \b \c \( \) \" \\" bbb"# + "\r\n" +
            "folded: aaa" + "\r\n" +
            "   bbb ccc" + "\r\n" +
            "tab_folded: aaa" + "\r\n" +
            "\t \t bbb ccc" + "\r\n" +
            "folded_in_comment: aaa (bbb" + "\r\n" +
            "   ccc) ddd" + "\r\n" +
            #"folded_in_quote: aaa "bbb"# + "\r\n" +
            #"   ccc" ddd"# + "\r\n" +
            "nested_comment: aaa (bbb (ccc (()ddd))) eee" + "\r\n" +
            #"escaped_comment: aaa \(bbb\) (ccc \) ddd) eee"# + "\r\n" +
            #"quoted: aaa "bbb (ccc) \"ddd\" eee" fff"# + "\r\n" +
            #"quoted_in_comment: aaa (bbb "ccc" ddd) eee"# + "\r\n" +
            "no_space_with_separator:aaa bbb ccc" + "\r\n" +
            "multi_space_with_separator:   aaa bbb ccc" + "\r\n" +
            "tab_with_separator:\t\taaa bbb ccc" + "\r\n" +
            "trailing_space: aaa bbb ccc \t \t" + "\r\n" +
            "duplicated_field: aaa bbb" + "\r\n" +
            "duplicated_field: ccc ddd" + "\r\n" +
            "\r\n" +
            "end" + "\r\n"
        #expect(body == expect)
    }
    
    @Test func testParseData_noHeader() async throws {
        let data =
            "\r\n" +
            "\r\n" +
            "body" + "\r\n"
        
        let parser = SmtpParser()
        let (header, body) = parser.parseData(data)
        
        #expect(header.isEmpty)
        #expect(body == "body" + "\r\n")
    }
    
    @Test func testParseData_noBody() async throws {
        let data = "subject: test" + "\r\n"
        
        let parser = SmtpParser()
        let (header, body) = parser.parseData(data)
        
        #expect(header["SUBJECT"] == ["test"])
        #expect(body == "")
    }
    
    @Test func testParseData_empty() async throws {
        let data = ""
        
        let parser = SmtpParser()
        let (header, body) = parser.parseData(data)
        
        #expect(header.isEmpty)
        #expect(body == "")
    }
    
    @Test func testParseAddressList() async throws {
        let list =
            "aaa@test.com," +
            "bbb <bbb@test.com>," +
            "group1: ccc@test.com, ddd <ddd@test.com>;," +
            "eee <eee@test.com>," +
            "group2: fff <fff@test.com>;," +
            "group3: ggg <ggg@test.com>;," +
            "hhh@test.com," +
            "iii <iii@test.com>"
        
        let parser = SmtpParser()
        let result = parser.parseAddressList(list)
        #expect(result.count == 8)
        #expect(result[0].groupName == "")
        #expect(result[0].group.count == 1)
        #expect(result[0].group[0].name == "")
        #expect(result[0].group[0].address == "aaa@test.com")
        
        #expect(result[1].groupName == "")
        #expect(result[1].group.count == 1)
        #expect(result[1].group[0].name == "bbb")
        #expect(result[1].group[0].address == "bbb@test.com")
        
        #expect(result[2].groupName == "group1")
        #expect(result[2].group.count == 2)
        #expect(result[2].group[0].name == "")
        #expect(result[2].group[0].address == "ccc@test.com")
        #expect(result[2].group[1].name == "ddd")
        #expect(result[2].group[1].address == "ddd@test.com")
        
        #expect(result[3].groupName == "")
        #expect(result[3].group.count == 1)
        #expect(result[3].group[0].name == "eee")
        #expect(result[3].group[0].address == "eee@test.com")
        
        #expect(result[4].groupName == "group2")
        #expect(result[4].group.count == 1)
        #expect(result[4].group[0].name == "fff")
        #expect(result[4].group[0].address == "fff@test.com")
        
        #expect(result[5].groupName == "group3")
        #expect(result[5].group.count == 1)
        #expect(result[5].group[0].name == "ggg")
        #expect(result[5].group[0].address == "ggg@test.com")
        
        #expect(result[6].groupName == "")
        #expect(result[6].group.count == 1)
        #expect(result[6].group[0].name == "")
        #expect(result[6].group[0].address == "hhh@test.com")
        
        #expect(result[7].groupName == "")
        #expect(result[7].group.count == 1)
        #expect(result[7].group[0].name == "iii")
        #expect(result[7].group[0].address == "iii@test.com")
    }
    
    @Test func testParseAddressList_group() async throws {
        let list = "group1: aaa@test.com, bbb <bbb@test.com>;"
        
        let parser = SmtpParser()
        let result = parser.parseAddressList(list)
        #expect(result.count == 1)
        #expect(result[0].groupName == "group1")
        #expect(result[0].group.count == 2)
        #expect(result[0].group[0].name == "")
        #expect(result[0].group[0].address == "aaa@test.com")
        #expect(result[0].group[1].name == "bbb")
        #expect(result[0].group[1].address == "bbb@test.com")
    }
    
    @Test func testParseAddressList_addressOnly() async throws {
        let list = "aaa@test.com"
        
        let parser = SmtpParser()
        let result = parser.parseAddressList(list)
        #expect(result.count == 1)
        #expect(result[0].groupName == "")
        #expect(result[0].group.count == 1)
        #expect(result[0].group[0].name == "")
        #expect(result[0].group[0].address == "aaa@test.com")
    }
    
    @Test func testParseAddressList_namedAddress() async throws {
        let list = "aaa <aaa@test.com>"
        
        let parser = SmtpParser()
        let result = parser.parseAddressList(list)
        #expect(result.count == 1)
        #expect(result[0].groupName == "")
        #expect(result[0].group.count == 1)
        #expect(result[0].group[0].name == "aaa")
        #expect(result[0].group[0].address == "aaa@test.com")
    }
    
    @Test func testParseAddressList_comment() async throws {
        let list = #"aaa(bbb, (()ccc\) ddd)) <aaa(eee)@(fff)test.com>"#
        
        let parser = SmtpParser()
        let result = parser.parseAddressList(list)
        #expect(result.count == 1)
        #expect(result[0].groupName == "")
        #expect(result[0].group.count == 1)
        #expect(result[0].group[0].name == #"aaa(bbb, (()ccc\) ddd))"#)
        #expect(result[0].group[0].address == "aaa(eee)@(fff)test.com")
    }
    
    @Test func testParseAddressList_quote() async throws {
        let list = #"aaa "bbb, \"ccc\" ddd" eee <aaa"bbb"@test.com>"#
        
        let parser = SmtpParser()
        let result = parser.parseAddressList(list)
        #expect(result.count == 1)
        #expect(result[0].groupName == "")
        #expect(result[0].group.count == 1)
        #expect(result[0].group[0].name == #"aaa "bbb, \"ccc\" ddd" eee"#)
        #expect(result[0].group[0].address == #"aaa"bbb"@test.com"#)
    }
    
    @Test func testParseDateTime() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let parser = SmtpParser()
        var date = parser.parseDateTime("Fri, 26 Jun 2026 11:30:50 +0900")
        #expect(formatter.string(from: date ?? .distantPast) == "2026-06-26 11:30:50")
        
        date = parser.parseDateTime("26 Jun 2026 11:30 +0900")
        #expect(formatter.string(from: date ?? .distantPast) == "2026-06-26 11:30:00")
        
        date = parser.parseDateTime("1 Jun 2026 11:30 +0900")
        #expect(formatter.string(from: date ?? .distantPast) == "2026-06-01 11:30:00")
        
        date = parser.parseDateTime("01 Jun 2026 11:30 +0900")
        #expect(formatter.string(from: date ?? .distantPast) == "2026-06-01 11:30:00")
        
        date = parser.parseDateTime("Fri, 26 Jun 2026 11:30:50 +0000")
        #expect(formatter.string(from: date ?? .distantPast) == "2026-06-26 20:30:50")
        
        date = parser.parseDateTime("Fri, 26 Jun 2026 11:30:50 +09:00")
        #expect(formatter.string(from: date ?? .distantPast) == "2026-06-26 11:30:50")
        
        date = parser.parseDateTime("   Fri,    26     Jun     2026    11:30:50    +0900   ")
        #expect(formatter.string(from: date ?? .distantPast) == "2026-06-26 11:30:50")
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
