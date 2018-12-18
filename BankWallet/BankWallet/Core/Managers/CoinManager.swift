import RxSwift

class CoinManager {
    private let disposeBag = DisposeBag()

    private let wordsManager: IWordsManager
    private let walletManager: IWalletManager
    private let appConfigProvider: IAppConfigProvider

    init(wordsManager: IWordsManager, walletManager: IWalletManager, appConfigProvider: IAppConfigProvider) {
        self.wordsManager = wordsManager
        self.walletManager = walletManager
        self.appConfigProvider = appConfigProvider

        syncWallets()

        wordsManager.loggedInSubject
                .subscribe(onNext: { [weak self] _ in
                    self?.syncWallets()
                })
                .disposed(by: disposeBag)
    }

    private var defaultCoins: [Coin] {
        let suffix = appConfigProvider.networkType == .main ? "" : "t"
        return [
            Coin(title: "Bitcoin", code: "BTC\(suffix)", blockChain: .bitcoin(type: .bitcoin)),
            Coin(title: "Bitcoin Cash", code: "BCH\(suffix)", blockChain: .bitcoin(type: .bitcoinCash)),
            Coin(title: "Ethereum", code: "ETH\(suffix)", blockChain: .ethereum(type: .ethereum))
        ]
    }

    private func syncWallets() {
        guard let words = wordsManager.words else {
            walletManager.clearWallets()
            return
        }

        walletManager.initWallets(words: words, coins: defaultCoins)
    }

}

extension CoinManager: ICoinManager {

}
