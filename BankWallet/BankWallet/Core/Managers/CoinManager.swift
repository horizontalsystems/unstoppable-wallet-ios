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

    private func syncWallets() {
        guard let authData = wordsManager.authData else {
            walletManager.clearWallets()
            return
        }

        walletManager.initWallets(authData: authData, coins: appConfigProvider.enabledCoins)
    }
}

extension CoinManager: ICoinManager {

}
