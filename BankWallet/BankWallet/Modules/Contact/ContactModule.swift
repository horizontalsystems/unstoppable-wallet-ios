protocol IContactView: class {
    func set(email: String)
    func set(telegramWalletHelperGroup: String)
    func set(telegramDevelopersGroup: String)
    func showCopied()
}

protocol IContactViewDelegate {
    func viewDidLoad()
    func didTapEmail()
    func didTapTelegramWalletHelp()
    func didTapTelegramDevelopers()
    func didTapStatus()
    func didTapDebugLog()
}

protocol IContactInteractor {
    var email: String { get }
    var telegramWalletHelperGroup: String { get }
    var telegramDevelopersGroup: String { get }
    func copyToClipboard(string: String)
}

protocol IContactRouter {
    var canSendMail: Bool { get }
    func openSendMail(recipient: String)
    func openTelegram(group: String)
    func openStatus()
    func showDebugLog()
}
