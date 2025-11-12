//
//  SocketService.swift
//  Socket-iO
//
//  Created by jaegu park on 11/12/25.
//

import Foundation
import SocketIO

final class SocketService {
    static let shared = SocketService()
    private let manager: SocketManager
    private let socket: SocketIOClient
    
    private init() {
        let url = URL(string: "http://localhost:3000")! // 추후 바꾸기
        manager = SocketManager(socketURL: url, config: [
            .log(true),
            .compress,
            .reconnects(true),
            .reconnectAttempts(-1),  // 무한 재시도
            .reconnectWait(2),       // 2초 간격
        ])
        socket = manager.defaultSocket
    }
    
    func connect(nickname: String, onMessage: @escaping (ChatMessage) -> Void,
                 onTyping: ((String) -> Void)? = nil,
                 onConnect: (() -> Void)? = nil,
                 onDisconnect: ((String) -> Void)? = nil) {
        
        socket.on(clientEvent: .connect) { _, _ in
            onConnect?()
            self.emitJoin(nickname: nickname)
        }
        
        socket.on(clientEvent: .disconnect) { data, _ in
            onDisconnect?((data.first as? String) ?? "disconnected")
        }
        
        socket.on("message") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let msg = ChatMessage.from(dict: dict) else { return }
            onMessage(msg)
        }
        
        socket.on("typing") { data, _ in
            if let name = (data.first as? [String: Any])?["user"] as? String {
                onTyping?(name)
            }
        }
        
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
        socket.removeAllHandlers()
    }
    
    func emitJoin(nickname: String) {
        socket.emit("join", ["user": nickname, "room": "lobby"])
    }
    
    func send(text: String, nickname: String) {
        let payload: [String: Any] = [
            "user": nickname,
            "room": "lobby",
            "text": text,
            "timestamp": Date().timeIntervalSince1970
        ]
        // ACK 예시(필요 시)
        socket.emitWithAck("message", payload).timingOut(after: 5) { _ in }
    }
    
    func emitTyping(nickname: String) {
        socket.emit("typing", ["user": nickname, "room": "lobby"])
    }
}
