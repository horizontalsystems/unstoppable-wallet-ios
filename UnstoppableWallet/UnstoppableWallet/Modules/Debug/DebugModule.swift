protocol IDebugView: class {
    func set(logs: [String])
}

protocol IDebugViewDelegate {
    func viewDidLoad()
    func onClear()
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
