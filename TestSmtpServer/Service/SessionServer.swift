//
//  SessionServer.swift
//  TestSmtpServer
//
//  Created by uhimania on 2026/06/16.
//

import Foundation
import Socket
import SSLService

actor Logger {
    static let shared = Logger()
    
    private(set) var log: String = ""
    private var continuations: [UUID: AsyncStream<String>.Continuation] = [:]
    
    func log(_ msg: String, _ socket: Socket? = nil) {
        var msg = msg
        if let socket = socket {
            msg = "[\(socket.remoteHostname):\(socket.remotePort)] \(msg)"
        }
        log.append(msg + "\n")
        
        continuations.values.forEach { $0.yield(log) }
    }
    
    func log(_ error: Error, _ socket: Socket? = nil) {
        var msg = if let error = error as? Socket.Error {
            error.description
        } else if let error = error as? SSLError {
            error.description
        } else {
            error.localizedDescription
        }
        if let socket = socket {
            msg = "[\(socket.remoteHostname):\(socket.remotePort)] \(msg)"
        }
        log.append(msg + "\n")
        
        continuations.values.forEach { $0.yield(log) }
    }
    
    func getLogStream() -> AsyncStream<String> {
        AsyncStream { continuation in
            if !log.isEmpty {
                continuation.yield(log)
            }
            
            let id = UUID()
            continuations[id] = continuation
            continuation.onTermination = { _ in
                Task {
                    await self.removeContinuation(forKey: id)
                }
            }
        }
    }
    
    private func removeContinuation(forKey key: UUID) {
        continuations.removeValue(forKey: key)
    }
}

enum SessionAction: Equatable {
    case write(String)
    case startTLS
    case close
}

protocol Session {
    associatedtype Dependency
    init(_ dependency: Dependency)
    func onConnect() -> [SessionAction]
    func onSwitchedToSSL()
    func handle(_ chunk: Data) async -> [SessionAction]
}

class SessionServer<T: Session> {
    private actor SocketActor {
        private(set) var socket: Socket
        private let certificateRepository: CertificateRepository?
        
        init(_ socket: Socket, _ certificateRepository: CertificateRepository? = nil) {
            self.socket = socket
            self.certificateRepository = certificateRepository
        }
        
        func switchToSSL(asServer: Bool) async throws {
            guard let repository = certificateRepository else { return }
            try repository.load(forKey: Constants.certificateKey) { url, password in
                do {
                    try switchToSSL(asServer: asServer, certificate: url, password: password)
                } catch {
                    Task {
                        await Logger.shared.log(error, socket)
                    }
                }
            }
        }
        
        private func switchToSSL(asServer: Bool, certificate: URL, password: String) throws {
            let config = SSLService.Configuration(withChainFilePath: certificate.path(), withPassword: password)
            socket.delegate = try SSLService(usingConfiguration: config)
            try socket.delegate?.initialize(asServer: asServer)
            try socket.delegate?.onConnect(socket: socket)
        }
    }
    
    private class Listener {
        private let socket: SocketActor
        private var task: Task<(), any Error>? = nil
        private var closed = false
        
        init() throws {
            let socket = try Socket.create()
            try socket.setBlocking(mode: false)
            self.socket = SocketActor(socket)
        }
        
        deinit {
            close()
            
            Task {
                await Logger.shared.log("listener deinit")
            }
        }
        
        func listen(on port: Int, onConnect: @escaping (Socket) async -> Void) {
            task = Task {
                try await socket.socket.listen(on: port)
                await Logger.shared.log("start listening on port \(port)")
                
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(for: .milliseconds(500))
                        
                        let newSocket = try await socket.socket.acceptClientConnection()
                        await onConnect(newSocket)
                    } catch {
                        if let error = error as? Socket.Error,
                           error.errorCode == Socket.SOCKET_ERR_ACCEPT_FAILED {
                            continue
                        } else if let _ = error as? CancellationError {
                            break
                        }
                        
                        await Logger.shared.log(error)
                    }
                }
            }
        }
        
        func close() {
            guard closed == false else { return }
            
            task?.cancel()
            Task {
                await socket.socket.close()
            }
            closed = true
        }
    }
    
    private class Connection {
        let id: Int32
        private let socket: SocketActor
        private let session: T
        private var task: Task<(), any Error>? = nil
        private var closed = false
        
        init(_ socket: Socket, _ certificateRepository: CertificateRepository, _ dependency: T.Dependency) {
            self.id = socket.socketfd
            self.socket = SocketActor(socket, certificateRepository)
            self.session = T(dependency)
        }
        
        deinit {
            close()
            
            let copiedId = self.id
            Task {
                await Logger.shared.log("connection #\(copiedId) deinit")
            }
        }
        
        func beginRead(onComplete: @escaping (Connection) async -> Void) {
            task = Task {
                let actions = session.onConnect()
                try await handleActions(actions)
                
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(for: .milliseconds(10))
                        
                        guard try await socket.socket.isReadableOrWritable().readable else {
                            continue
                        }
                        
                        var chunk = Data(capacity: 4096)
                        let length = try await socket.socket.read(into: &chunk)
                        if length == 0 {
                            await Logger.shared.log("no data received", await socket.socket)
                            close()
                            break
                        }
                        
                        if let received = String(data: chunk, encoding: .utf8) {
                            await Logger.shared.log(received, await socket.socket)
                        }
                        
                        let actions = await session.handle(chunk)
                        try await handleActions(actions)
                    } catch {
                        await Logger.shared.log(error, await socket.socket)
                        close()
                        break
                    }
                }
                
                await onComplete(self)
            }
        }
        
        private func handleActions(_ actions: [SessionAction]) async throws {
            for action in actions {
                switch action {
                case .write(let msg):
                    await Logger.shared.log("response: \(msg)", await socket.socket)
                    try await socket.socket.write(from: msg)
                case .startTLS:
                    try await socket.switchToSSL(asServer: true)
                    session.onSwitchedToSSL()
                case .close:
                    close()
                }
            }
        }
        
        func close() {
            guard closed == false else { return }
            
            task?.cancel()
            Task {
                await socket.socket.close()
            }
            closed = true
        }
    }
    
    private actor Connections {
        private var connections: [Connection] = []
        
        func append(_ connection: Connection) {
            connections.append(connection)
        }
        
        func remove(_ connection: Connection) {
            connections.removeAll { $0.id == connection.id }
        }
        
        func closeAll() {
            connections.forEach { $0.close() }
            connections.removeAll()
        }
    }
    
    private let certificateRepository: CertificateRepository
    private let networkSettingRepository: NetworkSettingRepository
    private let dependency: T.Dependency
    private var listener: Listener? = nil
    private let connections = Connections()
    
    var isRunning: Bool {
        listener != nil
    }
    
    init(_ certificateRepository: CertificateRepository, _ networkSettingRepository: NetworkSettingRepository, _ dependency: T.Dependency) {
        self.certificateRepository = certificateRepository
        self.networkSettingRepository = networkSettingRepository
        self.dependency = dependency
    }
    
    func run() {
        guard listener == nil else { return }
        
        do {
            let listener = try Listener()
            self.listener = listener
            
            listener.listen(on: networkSettingRepository.port) { newSocket in
                await Logger.shared.log("accepted connection", newSocket)
                
                let connection = Connection(newSocket, self.certificateRepository, self.dependency)
                await self.connections.append(connection)
                connection.beginRead { connection in
                    await self.connections.remove(connection)
                }
            }
        } catch {
            Task {
                await Logger.shared.log(error)
            }
        }
    }
    
    func stop() {
        Task {
            await connections.closeAll()
        }
        listener?.close()
        listener = nil
    }
}
