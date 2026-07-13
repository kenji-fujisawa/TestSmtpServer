//
//  CertificateSettingViewModelTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/18.
//

import Foundation
import Testing

@testable import TestSmtpServer

struct CertificateSettingViewModelTests {

    @Test func testInit() async throws {
        let repository = FakeCertificateRepository()
        var viewModel = CertificateSettingViewModel(repository)
        #expect(viewModel.certificate == "")
        #expect(viewModel.password == "")
        
        repository.certificate = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")
        repository.password = "pass"
        viewModel = CertificateSettingViewModel(repository)
        #expect(viewModel.certificate == repository.certificate?.path())
        #expect(viewModel.password == repository.password)
    }
    
    @Test func testUpdateCertificate() async throws {
        let repository = FakeCertificateRepository()
        let viewModel = CertificateSettingViewModel(repository)
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")
        viewModel.updateCertificate(url)
        #expect(repository.certificate == url)
        #expect(repository.password == "")
        #expect(viewModel.certificate == url.path())
        #expect(viewModel.password == "")
    }
    
    @Test func testUpdatePassword() async throws {
        let repository = FakeCertificateRepository()
        let viewModel = CertificateSettingViewModel(repository)
        
        let password = "pass"
        viewModel.updatePassword(password)
        #expect(repository.certificate == nil)
        #expect(repository.password == password)
        #expect(viewModel.certificate == "")
        #expect(viewModel.password == password)
    }
    
    class FakeCertificateRepository: CertificateRepository {
        var certificate: URL? = nil
        var password: String = ""
        
        func save(certificate: URL, password: String, forKey key: String) throws {
            self.certificate = certificate
            self.password = password
        }
        
        func save(certificate: URL, forKey key: String) throws {
            self.certificate = certificate
        }
        
        func save(password: String, forKey key: String) throws {
            self.password = password
        }
        
        func load(forKey key: String, callback: (URL, String) -> Void) throws {
            if let url = certificate {
                callback(url, password)
            }
        }
        
        func remove(forKey key: String) throws {}
    }
}
