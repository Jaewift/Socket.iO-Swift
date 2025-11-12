//
//  ChatMessage.swift
//  Socket-iO
//
//  Created by jaegu park on 11/12/25.
//

import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: String
    let user: String
    let text: String
    let timestamp: Date

    static func from(dict: [String: Any]) -> ChatMessage? {
        guard let user = dict["user"] as? String,
              let text = dict["text"] as? String,
              let ts = dict["timestamp"] as? TimeInterval else { return nil }
        return ChatMessage(id: UUID().uuidString, user: user, text: text, timestamp: Date(timeIntervalSince1970: ts))
    }
}
