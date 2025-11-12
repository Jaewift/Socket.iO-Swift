//
//  ViewController.swift
//  Socket-iO
//
//  Created by jaegu park on 11/12/25.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
    private let tableView = UITableView()
    private var messages: [ChatMessage] = []
    private let nickname: String
    
    init(nickname: String) {
        self.nickname = nickname
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Input Bar
    private lazy var inputBar: UIView = {
        let container = UIView()
        container.backgroundColor = .systemBackground
        
        container.autoresizingMask = [.flexibleHeight]
        container.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 56)
        
        container.addSubview(sendButton)
        container.addSubview(textView)
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sendButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor, constant: -8),
            sendButton.widthAnchor.constraint(equalToConstant: 64),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
            
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            textView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            textView.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor, constant: -8),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
        return container
    }()
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.layer.cornerRadius = 8
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.separator.cgColor
        tv.font = .systemFont(ofSize: 16)
        return tv
    }()
    
    private lazy var sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Send", for: .normal)
        b.addTarget(self, action: #selector(tapSend), for: .touchUpInside)
        return b
    }()
    
    override var inputAccessoryView: UIView? { inputBar }
    override var canBecomeFirstResponder: Bool { true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lobby"
        view.backgroundColor = .systemBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 소켓 연결
        SocketService.shared.connect(
            nickname: nickname,
            onMessage: { [weak self] msg in
                DispatchQueue.main.async {
                    self?.messages.append(msg)
                    self?.tableView.reloadData()
                    self?.scrollToBottom()
                }
            },
            onTyping: { [weak self] name in
                self?.showTypingToast("\(name) is typing...")
            },
            onConnect: { [weak self] in
                DispatchQueue.main.async { self?.showTypingToast("Connected") }
            },
            onDisconnect: { [weak self] reason in
                DispatchQueue.main.async { self?.showTypingToast("Disconnected: \(reason)") }
            }
        )
        
        textView.delegate = self
    }
    
    deinit { SocketService.shared.disconnect() }
    
    @objc private func tapSend() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        SocketService.shared.send(text: text, nickname: nickname)
        textView.text = nil
        SocketService.shared.emitTyping(nickname: nickname) // 선택
    }
    
    func textViewDidChange(_ textView: UITextView) {
        SocketService.shared.emitTyping(nickname: nickname)
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let index = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: index, at: .bottom, animated: true)
    }
    
    // MARK: - UITableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: id) ??
        UITableViewCell(style: .subtitle, reuseIdentifier: id)
        let m = messages[indexPath.row]
        cell.textLabel?.text = m.text
        cell.detailTextLabel?.text = "\(m.user) • \(DateFormatter.chat.string(from: m.timestamp))"
        cell.selectionStyle = .none
        return cell
    }
    
    private func showTypingToast(_ text: String) {
        // 간단 토스트 대용
        self.navigationItem.prompt = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.navigationItem.prompt = nil
        }
    }
}

private extension DateFormatter {
    static let chat: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
}
