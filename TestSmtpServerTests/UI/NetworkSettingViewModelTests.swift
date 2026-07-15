//
//  NetworkSettingViewModelTests.swift
//  TestSmtpServerTests
//
//  Created by uhimania on 2026/07/14.
//

import Testing

@testable import TestSmtpServer

struct NetworkSettingViewModelTests {

    @Test func testInit() async throws {
        let repository = FakeNetworkSettingRepository()
        let viewModel = NetworkSettingViewModel(repository)
        #expect(viewModel.port == repository._port)
        #expect(viewModel.bufferSize == repository._bufferSize)
    }
    
    @Test func testUpdatePort() async throws {
        let repository = FakeNetworkSettingRepository()
        let viewModel = NetworkSettingViewModel(repository)
        viewModel.updatePort(999)
        #expect(viewModel.port == 999)
        #expect(repository._port == 999)
    }
    
    @Test func testUpdateBufferSize() async throws {
        let repository = FakeNetworkSettingRepository()
        let viewModel = NetworkSettingViewModel(repository)
        viewModel.updateBufferSize(999)
        #expect(viewModel.bufferSize == 999)
        #expect(repository._bufferSize == 999)
    }
    
    class FakeNetworkSettingRepository: NetworkSettingRepository {
        var _port: Int = 100
        var port: Int {
            get { _port }
            set { _port = newValue }
        }
        
        var _bufferSize: Int = 1000
        var bufferSize: Int {
            get { _bufferSize }
            set { _bufferSize = newValue }
        }
    }
}
