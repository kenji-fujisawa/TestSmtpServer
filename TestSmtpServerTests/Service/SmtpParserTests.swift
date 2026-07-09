//
//  SmtpParserTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/30.
//

import Foundation
import Testing

@testable import TestSmtpServer

struct SmtpParserTests {

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
        
        let parser = DefaultSmtpParser()
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
        let data = """
            \r\n\
            \r\n\
            body\r\n
            """
        
        let parser = DefaultSmtpParser()
        let (header, body) = parser.parseData(data)
        
        #expect(header.isEmpty)
        #expect(body == "body" + "\r\n")
    }
    
    @Test func testParseData_noBody() async throws {
        let data = "subject: test" + "\r\n"
        
        let parser = DefaultSmtpParser()
        let (header, body) = parser.parseData(data)
        
        #expect(header["SUBJECT"] == ["test"])
        #expect(body == "")
    }
    
    @Test func testParseData_empty() async throws {
        let data = ""
        
        let parser = DefaultSmtpParser()
        let (header, body) = parser.parseData(data)
        
        #expect(header.isEmpty)
        #expect(body == "")
    }
    
    @Test func testParseAddressList() async throws {
        let list = """
            aaa@test.com,\
            bbb <bbb@test.com>,\
            group1: ccc@test.com, ddd <ddd@test.com>;,\
            eee <eee@test.com>,\
            group2: fff <fff@test.com>;,\
            group3: ggg <ggg@test.com>;,\
            hhh@test.com,\
            iii <iii@test.com>
            """
        
        let parser = DefaultSmtpParser()
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
        
        let parser = DefaultSmtpParser()
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
        
        let parser = DefaultSmtpParser()
        let result = parser.parseAddressList(list)
        #expect(result.count == 1)
        #expect(result[0].groupName == "")
        #expect(result[0].group.count == 1)
        #expect(result[0].group[0].name == "")
        #expect(result[0].group[0].address == "aaa@test.com")
    }
    
    @Test func testParseAddressList_namedAddress() async throws {
        let list = "aaa <aaa@test.com>"
        
        let parser = DefaultSmtpParser()
        let result = parser.parseAddressList(list)
        #expect(result.count == 1)
        #expect(result[0].groupName == "")
        #expect(result[0].group.count == 1)
        #expect(result[0].group[0].name == "aaa")
        #expect(result[0].group[0].address == "aaa@test.com")
    }
    
    @Test func testParseAddressList_comment() async throws {
        let list = #"aaa(bbb, (()ccc\) ddd)) <aaa(eee)@(fff)test.com>"#
        
        let parser = DefaultSmtpParser()
        let result = parser.parseAddressList(list)
        #expect(result.count == 1)
        #expect(result[0].groupName == "")
        #expect(result[0].group.count == 1)
        #expect(result[0].group[0].name == #"aaa(bbb, (()ccc\) ddd))"#)
        #expect(result[0].group[0].address == "aaa(eee)@(fff)test.com")
    }
    
    @Test func testParseAddressList_quote() async throws {
        let list = #"aaa "bbb, \"ccc\" ddd" eee <aaa"bbb"@test.com>"#
        
        let parser = DefaultSmtpParser()
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
        
        let parser = DefaultSmtpParser()
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
    
    @Test func testParseQuotedPrintable() async throws {
        let parser = DefaultSmtpParser()
        var data = parser.parseQuotedPrintable("=E3=83=86=E3=82=B9=E3=83=88")
        var result = String(data: data, encoding: .utf8)
        #expect(result == "テスト")
        
        data = parser.parseQuotedPrintable("=83e=83X=83g")
        result = String(data: data, encoding: .shiftJIS)
        #expect(result == "テスト")
        
        data = parser.parseQuotedPrintable("=A5=C6=A5=B9=A5=C8")
        result = String(data: data, encoding: .japaneseEUC)
        #expect(result == "テスト")
        
        data = parser.parseQuotedPrintable("=1B$B%F%9%H=1B(B")
        result = String(data: data, encoding: .iso2022JP)
        #expect(result == "テスト")
        
        data = parser.parseQuotedPrintable("=E3=83=86=E3=82=\r\n=B9=E3=83=88")
        result = String(data: data, encoding: .utf8)
        #expect(result == "テスト")
    }
    
    @Test func testParseMimeHeader() async throws {
        let parser = DefaultSmtpParser()
        var result = parser.parseMimeHeader("=?utf-8?B?44OG44K544OI?=")
        #expect(result == "テスト")
        
        result = parser.parseMimeHeader("=?utf-8?Q?=E3=83=86=E3=82=B9=E3=83=88?=")
        #expect(result == "テスト")
        
        result = parser.parseMimeHeader("=?shift_jis?B?g2WDWINn?=")
        #expect(result == "テスト")
        
        result = parser.parseMimeHeader("=?shift_jis?Q?=83e=83X=83g?=")
        #expect(result == "テスト")
        
        result = parser.parseMimeHeader("=?sjis?B?g2WDWINn?=")
        #expect(result == "テスト")
        
        result = parser.parseMimeHeader("=?sjis?Q?=83e=83X=83g?=")
        #expect(result == "テスト")
        
        result = parser.parseMimeHeader("=?euc-jp?B?pcaluaXI?=")
        #expect(result == "テスト")
        
        result = parser.parseMimeHeader("=?euc-jp?Q?=A5=C6=A5=B9=A5=C8?=")
        #expect(result == "テスト")
        
        result = parser.parseMimeHeader("=?iso-2022-jp?B?GyRCJUYlOSVIGyhC?=")
        #expect(result == "テスト")
        
        result = parser.parseMimeHeader("=?iso-2022-jp?Q?=1B$B%F%9%H=1B(B?=")
        #expect(result == "テスト")
        
        result = parser.parseMimeHeader("=?utf-8?B?44GT44KT?= =?utf-8?B?44Gr44Gh44Gv?=")
        #expect(result == "こんにちは")
    }
    
    @Test func testParseMimeBody() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" text/html; charset="UTF-8"; name=index.html"#],
            "CONTENT-TRANSFER-ENCODING": ["7BIT"]
        ]
        let body = "test"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .text)
        #expect(result.contentType == "TEXT/HTML")
        #expect(result.charset == "UTF-8")
        #expect(result.body == "test")
    }
    
    @Test func testParseMimeBody_defaultHeader() async throws {
        let parser = DefaultSmtpParser()
        let header: [String: [String]] = [:]
        let body = "test"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .text)
        #expect(result.contentType == "TEXT/PLAIN")
        #expect(result.charset == "us-ascii")
        #expect(result.body == "test")
    }
    
    @Test func testParseMimeBody_base64() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" text/html; charset="UTF-8""#],
            "CONTENT-TRANSFER-ENCODING": ["BASE64"]
        ]
        let body = """
            44OG44K5\r\n\
            44OI
            """
        
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .text)
        #expect(result.contentType == "TEXT/HTML")
        #expect(result.charset == "UTF-8")
        #expect(result.body == "テスト")
    }
    
    @Test func testParseMimeBody_quotedPrintable() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" text/html; charset="UTF-8""#],
            "CONTENT-TRANSFER-ENCODING": ["QUOTED-PRINTABLE"]
        ]
        let body = """
            =E3=83=86=E3=82=B9=\r\n\
            =E3=83=88
            """
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .text)
        #expect(result.contentType == "TEXT/HTML")
        #expect(result.charset == "UTF-8")
        #expect(result.body == "テスト")
    }
    
    @Test func testParseMimeBody_shiftJIS() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" text/html; charset="Shift_JIS""#],
            "CONTENT-TRANSFER-ENCODING": ["BASE64"]
        ]
        let body = "g2WDWINn"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .text)
        #expect(result.contentType == "TEXT/HTML")
        #expect(result.charset == "Shift_JIS")
        #expect(result.body == "テスト")
    }
    
    @Test func testParseMimeBody_eucjp() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" text/html; charset="EUC-JP""#],
            "CONTENT-TRANSFER-ENCODING": ["BASE64"]
        ]
        let body = "pcaluaXI"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .text)
        #expect(result.contentType == "TEXT/HTML")
        #expect(result.charset == "EUC-JP")
        #expect(result.body == "テスト")
    }
    
    @Test func testParseMimeBody_eucjp_quotedPrintable() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" text/html; charset="EUC-JP""#],
            "CONTENT-TRANSFER-ENCODING": ["QUOTED-PRINTABLE"]
        ]
        let body = "=A5=C6=A5=B9=A5=C8"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .text)
        #expect(result.contentType == "TEXT/HTML")
        #expect(result.charset == "EUC-JP")
        #expect(result.body == "テスト")
    }
    
    @Test func testParseMimeBody_iso2022jp() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" text/html; charset="iso-2022-jp""#],
            "CONTENT-TRANSFER-ENCODING": ["BASE64"]
        ]
        let body = "GyRCJUYlOSVIGyhC"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .text)
        #expect(result.contentType == "TEXT/HTML")
        #expect(result.charset == "iso-2022-jp")
        #expect(result.body == "テスト")
    }
    
    @Test func testParseMimeBody_iso2022jp_7bit() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" text/html; charset="iso-2022-jp""#],
            "CONTENT-TRANSFER-ENCODING": ["7BIT"]
        ]
        let body = """
            \u{1B}$B$\"$\"$\"\u{1B}(B\r\n\
            \u{1B}$B$$$$$$\u{1B}(B\r\n\
            \u{1B}$B$&$&$&\u{1B}(B
            """
        
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .text)
        #expect(result.contentType == "TEXT/HTML")
        #expect(result.charset == "iso-2022-jp")
        #expect(result.body == "あああ\r\nいいい\r\nううう")
    }
    
    @Test func testParseMimeBody_multipart() async throws {
        let parser = DefaultSmtpParser()
        let header = ["CONTENT-TYPE": [#" multipart/mixed; boundary="__separator__""#]]
        let body = """
            --__separator__\r\n\
            Content-Type: text/plain; charset="utf-8"\r\n\
            Content-Transfer-Encoding: 7bit\r\n\
            \r\n\
            section1\r\n\
            --__separator__\r\n\
            Content-Type: multipart/alternative; boundary="__child__"\r\n\
            \r\n\
            --__child__\r\n\
            Content-Type: text/plain; charset="utf-8"\r\n\
            Content-Transfer-Encoding: 7bit\r\n\
            \r\n\
            section2-1\r\n\
            --__child__\r\n\
            Content-Type: multipart/related; boundary="__relate__"\r\n\
            \r\n\
            --__relate__\r\n\
            Content-Type: text/plain; charset="utf-8"\r\n\
            Content-Transfer-Encoding: 7bit\r\n\
            \r\n\
            section2-2-1\r\n\
            --__relate__\r\n\
            Content-Type: text/plain; charset="utf-8"\r\n\
            Content-Transfer-Encoding: 7bit\r\n\
            \r\n\
            section2-2-2\r\n\
            --__relate__--\r\n\
            --__child__--\r\n\
            --__separator__\r\n\
            Content-Type: text/plain; charset="utf-8"\r\n\
            Content-Transfer-Encoding: 7bit\r\n\
            \r\n\
            section3\r\n\
            \r\n\
            \r\n\
            test\r\n\
            --__separator__--\r\n\
            \r\n
            """
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .mixed)
        #expect(result.children.count == 3)
        #expect(result.children[0].type == .text)
        #expect(result.children[0].body == "section1\r\n")
        #expect(result.children[1].type == .alternative)
        #expect(result.children[1].children.count == 2)
        #expect(result.children[1].children[0].type == .text)
        #expect(result.children[1].children[0].body == "section2-1\r\n")
        #expect(result.children[1].children[1].type == .related)
        #expect(result.children[1].children[1].children.count == 2)
        #expect(result.children[1].children[1].children[0].type == .text)
        #expect(result.children[1].children[1].children[0].body == "section2-2-1\r\n")
        #expect(result.children[1].children[1].children[1].type == .text)
        #expect(result.children[1].children[1].children[1].body == "section2-2-2\r\n")
        #expect(result.children[2].type == .text)
        #expect(result.children[2].body == "section3\r\n\r\n\r\ntest\r\n")
        
        #expect(result.flatten.count == 5)
        #expect(result.flatten[0].type == .text)
        #expect(result.flatten[0].body == "section1\r\n")
        #expect(result.flatten[1].type == .text)
        #expect(result.flatten[1].body == "section2-1\r\n")
        #expect(result.flatten[2].type == .text)
        #expect(result.flatten[2].body == "section2-2-1\r\n")
        #expect(result.flatten[3].type == .text)
        #expect(result.flatten[3].body == "section2-2-2\r\n")
        #expect(result.flatten[4].type == .text)
        #expect(result.flatten[4].body == "section3\r\n\r\n\r\ntest\r\n")
    }
    
    @Test func testParseMimeBody_data() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" application/json; charset="utf-8""#],
            "CONTENT-TRANSFER-ENCODING": ["BASE64"],
            "CONTENT-DISPOSITION": [#"attachment; filename="=?utf-8?Q?test.json?=""#]
        ]
        let body = "eyJrZXkxIjoidmFsdWUiLCJrZXkyIjoxMTF9"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .data)
        #expect(result.contentType == "APPLICATION/JSON")
        #expect(result.charset == "utf-8")
        #expect(result.filename == "test.json")
        
        let json = String(data: result.data ?? Data(), encoding: .utf8)
        #expect(json == #"{"key1":"value","key2":111}"#)
    }
    
    @Test func testParseMimeBody_data_quotedPrintable() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" application/json; charset="utf-8""#],
            "CONTENT-TRANSFER-ENCODING": ["QUOTED-PRINTABLE"],
            "CONTENT-DISPOSITION": [#"attachment; filename="=?utf-8?Q?test.json?=""#]
        ]
        let body = #"{"key1":"=E3=83=86=E3=82=B9=E3=83=88","key2":111}"#
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .data)
        #expect(result.contentType == "APPLICATION/JSON")
        #expect(result.charset == "utf-8")
        #expect(result.filename == "test.json")
        
        let json = String(data: result.data ?? Data(), encoding: .utf8)
        #expect(json == #"{"key1":"テスト","key2":111}"#)
    }
    
    @Test func testParseMimeBody_RFC2231Filename() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" application/json; charset="utf-8""#],
            "CONTENT-TRANSFER-ENCODING": ["BASE64"],
            "CONTENT-DISPOSITION": [#"attachment; filename*0*=Shift_JIS''test%83e; filename*1*=%83X%83g; filename*2=test.json"#]
        ]
        let body = "eyJrZXkxIjoidmFsdWUiLCJrZXkyIjoxMTF9"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .data)
        #expect(result.contentType == "APPLICATION/JSON")
        #expect(result.charset == "utf-8")
        #expect(result.filename == "testテストtest.json")
        
        let json = String(data: result.data ?? Data(), encoding: .utf8)
        #expect(json == #"{"key1":"value","key2":111}"#)
    }
    
    @Test func testParseMimeBody_noContentDescription() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" application/json; charset="utf-8"; name="=?utf-8?Q?test.json?=""#],
            "CONTENT-TRANSFER-ENCODING": ["BASE64"]
        ]
        let body = "eyJrZXkxIjoidmFsdWUiLCJrZXkyIjoxMTF9"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .data)
        #expect(result.contentType == "APPLICATION/JSON")
        #expect(result.charset == "utf-8")
        #expect(result.filename == "test.json")
        
        let json = String(data: result.data ?? Data(), encoding: .utf8)
        #expect(json == #"{"key1":"value","key2":111}"#)
    }
    
    @Test func testParseMimeBody_noContentDescription_RFC2231() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#" application/json; charset="utf-8"; name*=euc-jp'ja'%A5%C6%A5%B9%A5%C8"#],
            "CONTENT-TRANSFER-ENCODING": ["BASE64"]
        ]
        let body = "eyJrZXkxIjoidmFsdWUiLCJrZXkyIjoxMTF9"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .data)
        #expect(result.contentType == "APPLICATION/JSON")
        #expect(result.charset == "utf-8")
        #expect(result.filename == "テスト")
        
        let json = String(data: result.data ?? Data(), encoding: .utf8)
        #expect(json == #"{"key1":"value","key2":111}"#)
    }
    
    @Test func testParseMimeBody_checkSplitParams() async throws {
        let parser = DefaultSmtpParser()
        let header = [
            "CONTENT-TYPE": [#"    application  / json; ;  charset = "utf-8";  name =  " test; test " "#],
            "CONTENT-TRANSFER-ENCODING": ["BASE64"]
        ]
        let body = "eyJrZXkxIjoidmFsdWUiLCJrZXkyIjoxMTF9"
        let result = parser.parseMimeBody(header: header, body: body)
        #expect(result.type == .data)
        #expect(result.contentType == "APPLICATION/JSON")
        #expect(result.charset == "utf-8")
        #expect(result.filename == " test; test ")
        
        let json = String(data: result.data ?? Data(), encoding: .utf8)
        #expect(json == #"{"key1":"value","key2":111}"#)
    }
}
