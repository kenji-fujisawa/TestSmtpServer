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
        
        processing = true
        Task {
            defer { processing = false }
            
            try? await userRepository.register(name: name, password: password)
            updateUsers()
        }
    }
    
    func deleteUser(name: String) {
        try? userRepository.unregister(name: name)
        updateUsers()
    }
}
