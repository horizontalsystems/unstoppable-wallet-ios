import RxSwift

class CoinManager {
    private let disposeBag = DisposeBag()

    private let wordsManager: IWordsManager
    private let walletManager: IWalletManager

    init(wordsManager: IWordsManager, walletManager: IWalletManager) {
        self.wordsManager = wordsManager
        self.walletManager = walletManager

        syncWallets()

        wordsManager.loggedInSubject
                .subscribe(onNext: { [weak self] _ in
                    self?.syncWallets()
                })
                .disposed(by: disposeBag)
    }

    private var enabledCoins: [Coin] {
        return ["BTCr", "ETHt"]
    }

    private func syncWallets() {
        guard let words = wordsManager.words else {
            walletManager.clearWallets()
            return
        }

        walletManager.initWallets(words: words, coins: enabledCoins)
    }
}

extension CoinManager: ICoinManager {

}
