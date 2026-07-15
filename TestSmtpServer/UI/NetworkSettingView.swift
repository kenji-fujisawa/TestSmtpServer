//
//  NetworkSettingView.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/07/13.
//

import SwiftUI

struct NetworkSettingView: View {
    @Bindable var viewModel: NetworkSettingViewModel
    @FocusState private var portFocused: Bool
    @FocusState private var bufferSizeFocused: Bool
    
    var body: some View {
        Form {
            TextField("ポート", value: $viewModel.port, format: .number, prompt: Text("ポート番号を入力"))
                .focused($portFocused)
                .onChange(of: portFocused) { oldValue, newValue in
                    if oldValue == true && newValue == false {
                        viewModel.updatePort(viewModel.port)
                    }
                }
                .onSubmit {
                    viewModel.updatePort(viewModel.port)
                }
            
            TextField("バッファサイズ", value: $viewModel.bufferSize, format: .number, prompt: Text("バッファサイズを入力"))
                .focused($bufferSizeFocused)
                .onChange(of: bufferSizeFocused) { oldValue, newValue in
                    if oldValue == true && newValue == false {
                        viewModel.updateBufferSize(viewModel.bufferSize)
                    }
                }
                .onSubmit {
                    viewModel.updateBufferSize(viewModel.bufferSize)
                }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    let repository = FakeNetworkSettingRepository()
    let viewModel = NetworkSettingViewModel(repository)
    NetworkSettingView(viewModel: viewModel)
}

private class FakeNetworkSettingRepository: NetworkSettingRepository {
    var port: Int { get { 0 } set {} }
    var bufferSize: Int { get { 0 } set {} }
}
