import Foundation
import RxSwift
import RxRelay

protocol IWalletAdapterServiceDelegate: AnyObject {
    func didPrepareAdapters()
    func didUpdate(balanceData: BalanceData, wallet: Wallet)
    func didUpdate(state: AdapterState, wallet: Wallet)
}

class WalletAdapterService {
    weak var delegate: IWalletAdapterServiceDelegate?

    private let adapterManager: AdapterManager
    private let disposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()

    private var adapterMap: [Wallet: IBalanceAdapter]

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet-adapter-service", qos: .userInitiated)

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager

        adapterMap = adapterManager.adapterMap.compactMapValues { $0 as? IBalanceAdapter }
        subscribeToAdapters()

        subscribe(disposeBag, adapterManager.adaptersReadyObservable) { [weak self] in
            self?.handleAdaptersReady(adapterMap: $0)
        }
    }

    private func handleAdaptersReady(adapterMap: [Wallet: IAdapter]) {
        queue.async {
            self.adapterMap = adapterMap.compactMapValues { $0 as? IBalanceAdapter }
            self.subscribeToAdapters()
            self.delegate?.didPrepareAdapters()
        }
    }

    private func subscribeToAdapters() {
        adaptersDisposeBag = DisposeBag()

        for (wallet, adapter) in adapterMap {
            subscribe(adaptersDisposeBag, adapter.balanceDataUpdatedObservable) { [weak self] in
                self?.delegate?.didUpdate(balanceData: $0, wallet: wallet)
            }

            subscribe(adaptersDisposeBag, adapter.balanceStateUpdatedObservable) { [weak self] in
                self?.delegate?.didUpdate(state: $0, wallet: wallet)
            }
        }
    }

}

extension WalletAdapterService {

    func isMainNet(wallet: Wallet) -> Bool? {
        queue.sync { adapterMap[wallet]?.isMainNet }
    }

    func balanceData(wallet: Wallet) -> BalanceData? {
        queue.sync { adapterMap[wallet]?.balanceData }
    }

    func state(wallet: Wallet) -> AdapterState? {
        queue.sync { adapterMap[wallet]?.balanceState }
    }

    func refresh() {
        adapterManager.refresh()
    }

}
