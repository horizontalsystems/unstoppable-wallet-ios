import RxSwift
import RxRelay

protocol IWalletAdapterServiceDelegate: AnyObject {
    func didPrepareAdapters()
    func didUpdate(balance: Decimal, balanceLocked: Decimal?, wallet: Wallet)
    func didUpdate(state: AdapterState, wallet: Wallet)
}

class WalletAdapterService {
    weak var delegate: IWalletAdapterServiceDelegate?

    private let adapterManager: IAdapterManager
    private let scheduler: ImmediateSchedulerType
    private let disposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()

    private var wallets = [Wallet]()

    init(adapterManager: IAdapterManager, scheduler: ImmediateSchedulerType) {
        self.adapterManager = adapterManager
        self.scheduler = scheduler

        subscribe(scheduler, disposeBag, adapterManager.adaptersReadyObservable) { [weak self] in
            self?.handleAdaptersReady()
        }
    }

    private func handleAdaptersReady() {
        subscribeToAdapters()
        delegate?.didPrepareAdapters()
    }

    private func subscribeToAdapters() {
        adaptersDisposeBag = DisposeBag()

        for wallet in wallets {
            guard let adapter = adapterManager.balanceAdapter(for: wallet) else {
                continue
            }

            subscribe(scheduler, adaptersDisposeBag, adapter.balanceUpdatedObservable) { [weak self] in
                self?.delegate?.didUpdate(balance: adapter.balance, balanceLocked: adapter.balanceLocked, wallet: wallet)
            }

            subscribe(scheduler, adaptersDisposeBag, adapter.balanceStateUpdatedObservable) { [weak self] in
                self?.delegate?.didUpdate(state: adapter.balanceState, wallet: wallet)
            }
        }
    }
}

extension WalletAdapterService {

    func set(wallets: [Wallet]) {
        self.wallets = wallets
        subscribeToAdapters()
    }

    func balance(wallet: Wallet) -> Decimal? {
        adapterManager.balanceAdapter(for: wallet)?.balance
    }

    func balanceLocked(wallet: Wallet) -> Decimal? {
        adapterManager.balanceAdapter(for: wallet)?.balanceLocked
    }

    func state(wallet: Wallet) -> AdapterState? {
        adapterManager.balanceAdapter(for: wallet)?.balanceState
    }

    func refresh() {
        adapterManager.refresh()
    }

}
