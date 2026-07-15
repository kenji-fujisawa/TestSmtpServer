//
//  CertificateSettingView.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/18.
//

import SwiftUI
import UniformTypeIdentifiers

struct CertificateSettingView: View {
    @Bindable var viewModel: CertificateSettingViewModel
    @State private var showImporter: Bool = false
    @FocusState private var passwordFocused: Bool
    var isUiTesting: Bool = false
    
    var body: some View {
        Form {
            HStack{
                LabeledContent("証明書") {
                    if viewModel.certificate.isEmpty {
                        Text("証明書を選択")
                    } else {
                        Text(viewModel.certificate)
                            .foregroundStyle(.primary)
                    }
                    Button("選択") {
                        if isUiTesting {
                            onFileSelected(.success([URL(filePath: "/aaa/bbb/ccc.pk12")]))
                        } else {
                            showImporter = true
                        }
                    }
                }
            }
            
            SecureField(text: $viewModel.password, prompt: Text("証明書のパスワードを入力")) {
                Text("パスワード")
            }
            .accessibilityIdentifier("text_password")
            .focused($passwordFocused)
            .onChange(of: passwordFocused) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    viewModel.updatePassword(viewModel.password)
                }
            }
            .onSubmit {
                viewModel.updatePassword(viewModel.password)
            }
            
            if let error = viewModel.error {
                HStack {
                    Spacer()
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pkcs12], allowsMultipleSelection: false) { result in
            onFileSelected(result)
        }
    }
    
    private func onFileSelected(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                viewModel.updateCertificate(url)
            }
        case .failure(let error):
            print(error)
        }
    }
}

#Preview {
    let repository = FakeCertificateRepository()
    let viewModel = CertificateSettingViewModel(repository)
    CertificateSettingView(viewModel: viewModel)
}

private class FakeCertificateRepository: CertificateRepository{
    func save(certificate: URL, password: String, forKey key: String) throws {}
    func save(certificate: URL, forKey key: String) throws {}
    func save(password: String, forKey key: String) throws {}
    
    func load(forKey key: String, callback: (URL, String) throws -> Void) throws {
        try callback(URL(filePath: "/aaa/bbb/ccc.p12"), "password")
    }
    
    func remove(forKey key: String) throws {}
}
