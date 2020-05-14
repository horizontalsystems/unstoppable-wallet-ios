protocol IBalanceErrorView: class {
    func set(coinTitle: String)
    func set(buttons: [BalanceErrorModule.Buttons])
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
    func adapter(for wallet: Wallet) -> IAdapter?
}

protocol IBalanceErrorInteractorDelegate: class {
}

protocol IBalanceErrorRouter {
    func close()
    func openPrivacySettings()
    func openReport()
}

class BalanceErrorModule {

    enum Buttons {
        case retry
        case changeSource
    }

}
