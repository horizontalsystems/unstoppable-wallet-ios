protocol IDebugView: class {
    func set(title: String)
    func set(buttonTitle: String)
    func set(logs: [String])
    func set(logs: [(String, Any)])
}

protocol IDebugViewDelegate {
    func viewDidLoad()
    func didTapButton(text: String)
}

protocol IDebugInteractor {
    var logs: [String] { get }
    func clearLogs()
}

protocol IDebugInteractorDelegate: class {
    func didEnterForeground()
}

protocol IDebugRouter {
}
