import Foundation
import RxSwift

class WalletBlockchainElementService {
    private let account: Account
    private let adapterService: WalletAdapterService
    private let walletManager: WalletManager
    private let disposeBag = DisposeBag()

    weak var delegate: IWalletElementServiceDelegate?

    init(account: Account, adapterService: WalletAdapterService, walletManager: WalletManager) {
        self.account = account
        self.adapterService = adapterService
        self.walletManager = walletManager

        subscribe(disposeBag, walletManager.activeWalletDataUpdatedObservable) { [weak self] walletData in
            guard walletData.account == self?.account else {
                return
            }

            self?.handleUpdated(wallets: walletData.wallets)
        }
    }

    private func handleUpdated(wallets: [Wallet]) {
        delegate?.didUpdate(elementState: .loaded(elements: wallets.map { .wallet(wallet: $0) }), elementService: self)
    }

}

extension WalletBlockchainElementService: IWalletElementService {

    var state: WalletModule.ElementState {
        .loaded(elements: walletManager.activeWallets.map { .wallet(wallet: $0) })
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
        delegate?.didUpdateElements(elementService: self)
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
