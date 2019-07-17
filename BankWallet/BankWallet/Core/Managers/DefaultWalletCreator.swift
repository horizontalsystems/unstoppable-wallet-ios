import RxSwift

class DefaultWalletCreator {
    private let walletManager: IWalletManager
    private let appConfigProvider: IAppConfigProvider
    private let walletFactory: IWalletFactory

    private let disposeBag = DisposeBag()

    init(walletManager: IWalletManager, appConfigProvider: IAppConfigProvider, walletFactory: IWalletFactory) {
        self.walletManager = walletManager
        self.appConfigProvider = appConfigProvider
        self.walletFactory = walletFactory
    }

    private func defaultWallets(account: Account) -> [Wallet] {
        var wallets = [Wallet]()

        for coinCode in defaultCoinCodes(accountType: account.type) {
            guard let coin = appConfigProvider.coins.first(where: { $0.code == coinCode }) else {
                continue
            }

            let wallet = walletFactory.wallet(coin: coin, account: account, syncMode: account.defaultSyncMode)
            wallets.append(wallet)
        }

        return wallets
    }

    private func defaultCoinCodes(accountType: AccountType) -> [CoinCode] {
        switch accountType {
        case let .mnemonic(words, _, _):
            if words.count == 12 {
                return ["BTC", "ETH"]
            }
        case .eos:
            return ["EOS"]
        default: ()
        }

        return []
    }

}

extension DefaultWalletCreator: IDefaultWalletCreator {

    func createWallets(account: Account) {
        var wallets = walletManager.wallets

        for defaultWallet in defaultWallets(account: account) {
            guard !wallets.contains(defaultWallet) else {
                continue
            }

            wallets.append(defaultWallet)
        }

        walletManager.enable(wallets: wallets)
    }

}
