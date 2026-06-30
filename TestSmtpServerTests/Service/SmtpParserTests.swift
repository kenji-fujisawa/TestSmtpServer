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
        let data =
            "\r\n" +
            "\r\n" +
            "body" + "\r\n"
        
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
        let list =
            "aaa@test.com," +
            "bbb <bbb@test.com>," +
            "group1: ccc@test.com, ddd <ddd@test.com>;," +
            "eee <eee@test.com>," +
            "group2: fff <fff@test.com>;," +
            "group3: ggg <ggg@test.com>;," +
            "hhh@test.com," +
            "iii <iii@test.com>"
        
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
        var result = parser.parseQuotedPrintable("=E3=83=86=E3=82=B9=E3=83=88", encoding: .utf8)
        #expect(result == "テスト")
        
        result = parser.parseQuotedPrintable("=83e=83X=83g", encoding: .shiftJIS)
        #expect(result == "テスト")
        
        result = parser.parseQuotedPrintable("=A5=C6=A5=B9=A5=C8", encoding: .japaneseEUC)
        #expect(result == "テスト")
        
        let iso2022jp = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.ISO_2022_JP.rawValue)))
        result = parser.parseQuotedPrintable("=1B$B%F%9%H=1B(B", encoding: iso2022jp)
        #expect(result == "テスト")
        
        result = parser.parseQuotedPrintable("=E3=83=86=E3=82=\r\n=B9=E3=83=88", encoding: .utf8)
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
}
