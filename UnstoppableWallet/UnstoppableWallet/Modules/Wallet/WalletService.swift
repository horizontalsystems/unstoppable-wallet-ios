import Foundation
import MarketKit
import RxSwift

protocol IWalletServiceDelegate: AnyObject {
    func didUpdateWallets(walletService: WalletService)
    func didUpdate(wallets: [Wallet], walletService: WalletService)
    func didUpdate(isMainNet: Bool, wallet: Wallet)
    func didUpdate(balanceData: BalanceData, wallet: Wallet)
    func didUpdate(state: AdapterState, wallet: Wallet)
}

class WalletService {
    private let account: Account
    private let adapterService: WalletAdapterService
    private let walletManager: WalletManager
    private let allowedBlockchainTypes: [BlockchainType]?
    private let allowedTokenTypes: [TokenType]?
    private let disposeBag = DisposeBag()

    weak var delegate: IWalletServiceDelegate?

    init(account: Account, adapterService: WalletAdapterService, walletManager: WalletManager, allowedBlockchainTypes: [BlockchainType]? = nil, allowedTokenTypes: [TokenType]? = nil) {
        self.account = account
        self.adapterService = adapterService
        self.walletManager = walletManager
        self.allowedBlockchainTypes = allowedBlockchainTypes
        self.allowedTokenTypes = allowedTokenTypes

        subscribe(disposeBag, walletManager.activeWalletDataUpdatedObservable) { [weak self] walletData in
            guard walletData.account == self?.account else {
                return
            }

            self?.handleUpdated(wallets: walletData.wallets)
        }
    }

    private func filtered(_ wallets: [Wallet]) -> [Wallet] {
        var wallets = wallets

        if let allowedBlockchainTypes {
            wallets = wallets.filter { wallet in allowedBlockchainTypes.contains(wallet.token.blockchainType) }
        }

        if let allowedTokenTypes {
            wallets = wallets.filter { wallet in allowedTokenTypes.contains(wallet.token.type) }
        }

        return wallets
    }

    private func handleUpdated(wallets: [Wallet]) {
        delegate?.didUpdate(wallets: filtered(wallets), walletService: self)
    }
}

extension WalletService {
    var wallets: [Wallet] {
        filtered(walletManager.activeWallets)
    }

    func isMainNet(wallet: Wallet) -> Bool? {
        adapterService.isMainNet(wallet: wallet)
    }

    func balanceData(wallet: Wallet) -> BalanceData? {
        adapterService.balanceData(wallet: wallet)
    }

    func state(wallet: Wallet) -> AdapterState? {
        adapterService.state(wallet: wallet)
    }

    func refresh() {
        adapterService.refresh()
    }

    func disable(wallet: Wallet) {
        walletManager.delete(wallets: [wallet])
    }
}

extension WalletService: IWalletAdapterServiceDelegate {
    func didPrepareAdapters() {
        delegate?.didUpdateWallets(walletService: self)
    }

    func didUpdate(isMainNet: Bool, wallet: Wallet) {
        delegate?.didUpdate(isMainNet: isMainNet, wallet: wallet)
    }

    func didUpdate(balanceData: BalanceData, wallet: Wallet) {
        delegate?.didUpdate(balanceData: balanceData, wallet: wallet)
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        delegate?.didUpdate(state: state, wallet: wallet)
    }
}
