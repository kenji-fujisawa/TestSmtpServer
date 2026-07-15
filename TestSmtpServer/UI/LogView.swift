//
//  LogView.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/19.
//

import SwiftUI

struct LogView: View {
    let viewModel: LogViewModel
    
    var body: some View {
        ScrollView {
            Text(viewModel.log)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.log.isEmpty)
            }
        }
    }
}

#Preview {
    let repository = FakeLogRepository()
    let viewModel = LogViewModel(repository)
    LogView(viewModel: viewModel)
}

private class FakeLogRepository: LogRepository {
    func getLogStream() -> AsyncStream<String> {
        AsyncStream { continuation in
            continuation.yield("test\naaabbb")
        }
    }
    
    func getLog() -> String { "" }
    func clear() async {}
}
