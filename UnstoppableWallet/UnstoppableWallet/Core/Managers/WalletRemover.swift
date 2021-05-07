import RxSwift

class WalletRemover {
    private let walletManager: IWalletManager

    private let disposeBag = DisposeBag()

    init(accountManager: IAccountManager, walletManager: IWalletManager) {
        self.walletManager = walletManager

        accountManager.accountDeletedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] account in
                    self?.handleDelete(account: account)
                })
                .disposed(by: disposeBag)

    }

    private func handleDelete(account: Account) {
        let accountWallets = walletManager.wallets.filter { $0.account == account }
        walletManager.delete(wallets: accountWallets)
    }

}
