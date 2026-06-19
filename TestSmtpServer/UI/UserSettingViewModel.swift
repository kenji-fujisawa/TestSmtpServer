//
//  UserSettingViewModel.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/18.
//

import Foundation

@Observable
class UserSettingViewModel {
    var users: [String] = []
    var processing: Bool = false
    var addError: String? = nil
    var deleteError: String? = nil
    
    @ObservationIgnored private let userRepository: UserRepository
    
    init(_ userRepository: UserRepository) {
        self.userRepository = userRepository
        self.updateUsers()
    }
    
    private func updateUsers() {
        if let users = try? userRepository.getUsers() {
            self.users = users.map { $0.name }
        }
    }
    
    func addUser(name: String, password: String) {
        guard processing == false else { return }
        
        addError = nil
        deleteError = nil
        
        processing = true
        Task { @MainActor in
            defer { processing = false }
            
            do {
                try await userRepository.register(name: name, password: password)
                updateUsers()
            } catch DefaultUserRepository.RegisterError.duplicateUser {
                addError = "ユーザ名が重複しています"
            } catch DefaultUserRepository.RegisterError.invalidName {
                addError = "ユーザ名が無効です"
            } catch DefaultUserRepository.RegisterError.invalidPassword {
                addError = "パスワードが無効です"
            } catch {
                addError = error.localizedDescription
            }
        }
    }
    
    func deleteUser(name: String) {
        addError = nil
        deleteError = nil
        
        do {
            try userRepository.unregister(name: name)
            updateUsers()
        } catch DefaultUserRepository.UnregisterError.notFound {
            deleteError = "ユーザが存在しません"
        } catch {
            deleteError = error.localizedDescription
        }
    }
}
