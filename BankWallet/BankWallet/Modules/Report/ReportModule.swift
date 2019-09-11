protocol IReportView: class {
    func set(email: String)
    func set(telegramGroup: String)
    func showCopied()
}

protocol IReportViewDelegate {
    func viewDidLoad()
    func didTapEmail()
    func didTapTelegram()
}

protocol IReportInteractor {
    var email: String { get }
    var telegramGroup: String { get }
    func copyToClipboard(string: String)
}

protocol IReportRouter {
    var canSendMail: Bool { get }
    func openSendMail(recipient: String)
    func openTelegram(group: String)
}
