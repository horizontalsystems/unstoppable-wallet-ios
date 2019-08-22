protocol IReportView: class {
    func showCopied()
}

protocol IReportViewDelegate {
    var email: String { get }
    var telegramGroup: String { get }
    func didTapEmail()
    func didTapTelegram()
}

protocol IReportInteractor {
    var email: String { get }
    var telegramGroup: String { get }
    func copyToClipboard(string: String)
}

protocol IReportInteractorDelegate: class {
}

protocol IReportRouter {
    var canSendMail: Bool { get }
    func openSendMail(recipient: String)
    func openTelegram(group: String)
}
