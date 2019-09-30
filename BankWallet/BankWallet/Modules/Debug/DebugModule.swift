protocol IDebugView: class {
    func set(logs: [String])
}

protocol IDebugViewDelegate {
    func viewDidLoad()
    func didTapClear()
}

protocol IDebugInteractor {
    var logs: [String] { get }
    func clearLogs()
}

protocol IDebugInteractorDelegate: class {
    func didEnterForeground()
    func didClearLogs()
}

protocol IDebugRouter {
}
