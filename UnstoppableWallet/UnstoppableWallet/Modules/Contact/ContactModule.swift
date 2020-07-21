protocol IContactView: class {
    func set(email: String)
    func set(telegramWalletHelpAccount: String)
    func showCopied()
}

protocol IContactViewDelegate {
    func viewDidLoad()
    func didTapEmail()
    func didTapTelegramWalletHelp()
    func didTapDebugLog()
}

protocol IContactInteractor {
    var email: String { get }
    var telegramWalletHelpAccount: String { get }
    func copyToClipboard(string: String)
}

protocol IContactRouter {
    var canSendMail: Bool { get }
    func openSendMail(recipient: String)
    func openTelegram(account: String)
    func showDebugLog()
}
