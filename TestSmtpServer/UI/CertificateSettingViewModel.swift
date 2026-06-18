//
//  CertificateSettingViewModel.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/18.
//

import Foundation

@Observable
class CertificateSettingViewModel {
    var certificate: String = ""
    var password: String = ""
    
    @ObservationIgnored private let certificateRepository: CertificateRepository
    
    init(_ certificateRepository: CertificateRepository) {
        self.certificateRepository = certificateRepository
        
        try? certificateRepository.load(forKey: Constants.certificateKey) { url, password in
            self.certificate = url.path()
            self.password = password
        }
    }
    
    func updateCertificate(_ url: URL) {
        try? certificateRepository.save(certificate: url, forKey: Constants.certificateKey)
        self.certificate = url.path()
    }
    
    func updatePassword(_ password: String) {
        try? certificateRepository.save(password: password, forKey: Constants.certificateKey)
        self.password = password
    }
}
