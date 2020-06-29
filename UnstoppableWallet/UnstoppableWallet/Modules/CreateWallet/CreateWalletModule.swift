protocol ICreateWalletView: class {
    func setCancelButton(visible: Bool)
    func set(featuredViewItems: [CoinToggleViewItem], viewItems: [CoinToggleViewItem])
    func setCreateButton(enabled: Bool)

    func show(error: Error)
}

protocol ICreateWalletViewDelegate {
    func onLoad()

    func onEnable(viewItem: CoinToggleViewItem)
    func onDisable(viewItem: CoinToggleViewItem)

    func onTapCreateButton()
    func onTapCancelButton()
}

protocol ICreateWalletInteractor {
    var coins: [Coin] { get }
    var featuredCoins: [Coin] { get }

    func account(predefinedAccountType: PredefinedAccountType) throws -> Account

    func create(accounts: [Account])
    func resetDerivationSettings()
    func save(wallets: [Wallet])
    func derivationSettings(coin: Coin) -> DerivationSetting?
}

protocol ICreateWalletRouter {
    func showMain()
    func close()
}

class CreateWalletModule {

    enum PresentationMode {
        case initial
        case inApp
    }

}
