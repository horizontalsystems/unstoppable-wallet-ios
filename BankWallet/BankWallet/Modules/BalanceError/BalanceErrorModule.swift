protocol IBalanceErrorView: class {
    func set(coinTitle: String)
    func setChangeSourceButton(hidden: Bool)
}

protocol IBalanceErrorViewDelegate {
    func onLoad()
    func onTapRetry()
    func onTapChangeSource()
    func onTapReport()

    func onTapClose()
}

protocol IBalanceErrorInteractor {
    func copyToClipboard(text: String)
    func refresh(wallet: Wallet)
}

protocol IBalanceErrorInteractorDelegate: class {
}

protocol IBalanceErrorRouter {
    func close()
    func closeAndOpenPrivacySettings()
    func closeAndOpenReport()
}
