//
//  UserSettingViewModelTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/06/18.
//

import Testing

@testable import TestSmtpServer

struct UserSettingViewModelTests {

    @Test func testInit() async throws {
        let repository = FakeUserRepository()
        var viewModel = UserSettingViewModel(repository)
        #expect(viewModel.users.count == 0)
        
        repository.users = [
            User(name: "user1", password: "pass1"),
            User(name: "user2", password: "pass2"),
            User(name: "user3", password: "pass3"),
        ]
        viewModel = UserSettingViewModel(repository)
        #expect(viewModel.users.count == 3)
        #expect(viewModel.users[0] == repository.users[0].name)
        #expect(viewModel.users[1] == repository.users[1].name)
        #expect(viewModel.users[2] == repository.users[2].name)
    }
    
    @Test func testAddUser() async throws {
        let repository = FakeUserRepository()
        let viewModel = UserSettingViewModel(repository)
        
        viewModel.addUser(name: "user1", password: "pass1")
        #expect(viewModel.processing == true)
        
        while viewModel.processing {
            await Task.yield()
        }
        
        #expect(viewModel.users.count == 1)
        #expect(viewModel.users[0] == "user1")
        #expect(repository.users.count == 1)
        #expect(repository.users[0].name == "user1")
        #expect(repository.users[0].password == "pass1")
        
        viewModel.addUser(name: "user2", password: "pass2")
        #expect(viewModel.processing == true)
        
        // if processing is true, do not add
        viewModel.addUser(name: "user3", password: "pass3")
        
        while viewModel.processing {
            await Task.yield()
        }
        
        #expect(viewModel.users.count == 2)
        #expect(viewModel.users[0] == "user1")
        #expect(viewModel.users[1] == "user2")
        #expect(repository.users.count == 2)
        #expect(repository.users[0].name == "user1")
        #expect(repository.users[0].password == "pass1")
        #expect(repository.users[1].name == "user2")
        #expect(repository.users[1].password == "pass2")
    }
    
    @Test func testDeleteUser() async throws {
        let repository = FakeUserRepository()
        let viewModel = UserSettingViewModel(repository)
        
        repository.users = [
            User(name: "user1", password: "pass1"),
            User(name: "user2", password: "pass2"),
            User(name: "user3", password: "pass3")
        ]
        
        viewModel.deleteUser(name: "user1")
        #expect(viewModel.users.count == 2)
        #expect(viewModel.users[0] == "user2")
        #expect(viewModel.users[1] == "user3")
        #expect(repository.users.count == 2)
        #expect(repository.users[0].name == "user2")
        #expect(repository.users[1].name == "user3")
        
        viewModel.deleteUser(name: "user3")
        #expect(viewModel.users.count == 1)
        #expect(viewModel.users[0] == "user2")
        #expect(repository.users.count == 1)
        #expect(repository.users[0].name == "user2")
        
        viewModel.deleteUser(name: "user4")
        #expect(viewModel.users.count == 1)
        #expect(viewModel.users[0] == "user2")
        #expect(repository.users.count == 1)
        #expect(repository.users[0].name == "user2")
    }
    
    class FakeUserRepository: UserRepository {
        var users: [User] = []
        
        func getUsers() throws -> [TestSmtpServer.User] {
            users
        }
        
        func register(name: String, password: String) async throws {
            users.append(User(name: name, password: password))
        }
        
        func unregister(name: String) throws {
            users.removeAll { $0.name == name }
        }
        
        func authenticate(name: String, password: String) async throws -> Bool { false }
    }
}
