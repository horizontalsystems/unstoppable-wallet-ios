protocol ICreateWalletView: class {
    func setCancelButton(visible: Bool)
    func set(featuredViewItems: [CoinToggleViewItem], viewItems: [CoinToggleViewItem])
    func setCreateButton(enabled: Bool)

    func showNotSupported(coin: Coin, predefinedAccountType: PredefinedAccountType)
    func show(error: Error)
}

protocol ICreateWalletViewDelegate {
    func onLoad()

    func onEnable(viewItem: CoinToggleViewItem)
    func onDisable(viewItem: CoinToggleViewItem)
    func onSelect(viewItem: CoinToggleViewItem)

    func onTapCreateButton()
    func onTapCancelButton()
}

protocol ICreateWalletInteractor {
    var coins: [Coin] { get }
    var featuredCoins: [Coin] { get }

    func account(predefinedAccountType: PredefinedAccountType) throws -> Account

    func create(accounts: [Account])
    func save(wallets: [Wallet])
    func save(settings: [BlockchainSetting])

    func blockchainSettings(coinType: CoinType) -> BlockchainSetting?
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
