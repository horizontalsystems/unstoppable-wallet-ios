protocol IDebugView: AnyObject {
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

protocol IDebugInteractorDelegate: AnyObject {
    func didEnterForeground()
}

protocol IDebugRouter {
}
