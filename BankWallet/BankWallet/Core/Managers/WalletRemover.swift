import RxSwift

class WalletRemover {
    private let walletManager: IWalletManager

    private let disposeBag = DisposeBag()

    init(accountManager: IAccountManager, walletManager: IWalletManager) {
        self.walletManager = walletManager

        accountManager.deleteAccountObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] id in
                    self?.handleDelete(accountId: id)
                })
                .disposed(by: disposeBag)

    }

    private func handleDelete(accountId: String) {
        let remainingWallets = walletManager.wallets.filter { $0.account.id != accountId }
        walletManager.enable(wallets: remainingWallets)
    }

}
