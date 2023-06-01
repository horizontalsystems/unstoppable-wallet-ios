import Foundation
import RxSwift

class WalletBlockchainElementService {
    private let adapterService: WalletAdapterService
    private let walletManager: WalletManager
    private let disposeBag = DisposeBag()

    weak var delegate: IWalletElementServiceDelegate?

    init(adapterService: WalletAdapterService, walletManager: WalletManager) {
        self.adapterService = adapterService
        self.walletManager = walletManager

        subscribe(disposeBag, walletManager.activeWalletsUpdatedObservable) { [weak self] in
            self?.delegate?.didUpdate(elements: $0.map { .wallet(wallet: $0) })
        }
    }

}

extension WalletBlockchainElementService: IWalletElementService {

    var elements: [WalletModule.Element] {
        walletManager.activeWallets.map { .wallet(wallet: $0) }
    }

    func isMainNet(element: WalletModule.Element) -> Bool? {
        guard let wallet = element.wallet else {
            return nil
        }

        return adapterService.isMainNet(wallet: wallet)
    }

    func balanceData(element: WalletModule.Element) -> BalanceData? {
        guard let wallet = element.wallet else {
            return nil
        }

        return adapterService.balanceData(wallet: wallet)
    }

    func state(element: WalletModule.Element) -> AdapterState? {
        guard let wallet = element.wallet else {
            return nil
        }

        return adapterService.state(wallet: wallet)
    }

    func refresh() {
        adapterService.refresh()
    }

    func disable(element: WalletModule.Element) {
        guard let wallet = element.wallet else {
            return
        }

        walletManager.delete(wallets: [wallet])
    }

}

extension WalletBlockchainElementService: IWalletAdapterServiceDelegate {

    func didPrepareAdapters() {
        delegate?.didUpdateElements()
    }

    func didUpdate(isMainNet: Bool, wallet: Wallet) {
        delegate?.didUpdate(isMainNet: isMainNet, element: .wallet(wallet: wallet))
    }

    func didUpdate(balanceData: BalanceData, wallet: Wallet) {
        delegate?.didUpdate(balanceData: balanceData, element: .wallet(wallet: wallet))
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        delegate?.didUpdate(state: state, element: .wallet(wallet: wallet))
    }

}
