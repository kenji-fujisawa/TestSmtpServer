//
//  UserSettingView.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/18.
//

import SwiftUI

struct UserSettingView: View {
    let viewModel: UserSettingViewModel
    @State private var name: String = ""
    @State private var password: String = ""
    @State private var selected: String? = nil
    
    var body: some View {
        Form {
            HStack {
                TextField(text: $name, prompt: Text("ユーザ名を入力")) {
                    Text("ユーザ名")
                }
                SecureField(text: $password, prompt: Text("パスワードを入力")) {
                    Text("パスワード")
                }
                Button("追加") {
                    viewModel.addUser(name: name, password: password)
                    name = ""
                    password = ""
                }
                .disabled(viewModel.processing)
                if viewModel.processing {
                    ProgressView()
                }
            }
            VStack {
                ScrollView {
                    List(viewModel.users, id: \.self, selection: $selected) { user in
                        Text(user)
                    }
                    .listStyle(.inset)
                    .frame(height: 150)
                }
                HStack {
                    Spacer()
                    Button("削除") {
                        if let user = selected {
                            viewModel.deleteUser(name: user)
                            selected = nil
                        }
                    }
                    .disabled(selected == nil)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    let repository = FakeUserRepository()
    let viewModel = UserSettingViewModel(repository)
    UserSettingView(viewModel: viewModel)
}

private class FakeUserRepository: UserRepository {
    func getUsers() throws -> [User] {
        [
            User(name: "user1", password: "pass1"),
            User(name: "user2", password: "pass2"),
            User(name: "user3", password: "pass3")
        ]
    }
    
    func register(name: String, password: String) async throws {}
    func unregister(name: String) throws {}
    func authenticate(name: String, password: String) async throws -> Bool { false }
}
