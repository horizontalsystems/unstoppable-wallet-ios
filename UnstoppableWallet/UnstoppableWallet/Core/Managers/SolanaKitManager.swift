import Combine
import Foundation
import HdWalletKit
import MarketKit
import RxRelay
import RxSwift
import SolanaKit

class SolanaKitManager {
    private let rpcSourceManager: SolanaRpcSourceManager
    private let restoreStateManager: RestoreStateManager
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager

    private var tokenAccountCancellable: AnyCancellable?
    private let rpcSourceDisposeBag = DisposeBag()

    private weak var _solanaKit: SolanaKit.Kit?
    private var currentAccount: Account?

    private let queue = DispatchQueue(label: "\(AppConfig.label).solana-kit-manager", qos: .userInitiated)
    private let kitStoppedRelay = PublishRelay<Void>()

    init(rpcSourceManager: SolanaRpcSourceManager, restoreStateManager: RestoreStateManager, marketKit: MarketKit.Kit, walletManager: WalletManager) {
        self.rpcSourceManager = rpcSourceManager
        self.restoreStateManager = restoreStateManager
        self.marketKit = marketKit
        self.walletManager = walletManager

        rpcSourceManager.rpcSourceObservable
            .observeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] in
                self?.handleRpcSourceUpdate()
            })
            .disposed(by: rpcSourceDisposeBag)
    }

    private func handleRpcSourceUpdate() {
        queue.async { [weak self] in
            guard let self else { return }
            _solanaKit = nil
            currentAccount = nil
            tokenAccountCancellable?.cancel()
            tokenAccountCancellable = nil
            kitStoppedRelay.accept(())
        }
    }

    private func _solanaKit(account: Account) throws -> SolanaKit.Kit {
        if let _solanaKit, let currentAccount, currentAccount == account {
            return _solanaKit
        }

        guard let seed = account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let address = try SolanaKit.Signer.address(seed: seed)
        let addressString = address.base58

        let kit = try SolanaKit.Kit.instance(
            address: addressString,
            rpcSource: rpcSourceManager.rpcSource,
            walletId: account.id
        )

        kit.start()

        _solanaKit = kit
        currentAccount = account

        subscribe(solanaKit: kit, account: account)

        return kit
    }

    private func subscribe(solanaKit: SolanaKit.Kit, account: Account) {
        tokenAccountCancellable = solanaKit.fungibleTokenAccountsPublisher
            .sink { [weak self, restoreStateManager] tokenAccounts in
                let restoreState = restoreStateManager.restoreState(account: account, blockchainType: .solana)

                restoreStateManager.setInitialRestored(account: account, blockchainType: .solana)

                if !restoreState.initialRestored, !restoreState.shouldRestore, !account.watchAccount {
                    return
                }

                self?.handle(tokenAccounts: tokenAccounts, account: account)

                self?.tokenAccountCancellable?.cancel()
                self?.tokenAccountCancellable = nil
            }
    }

    private func handle(tokenAccounts: [FullTokenAccount], account: Account) {
        guard !tokenAccounts.isEmpty else {
            return
        }

        let existingWallets = walletManager.activeWallets
        let existingTokenTypeIds = existingWallets.map(\.token.type.id)
        let newTokenAccounts = tokenAccounts.filter { fullAccount in
            let tokenType = TokenType.spl(address: fullAccount.tokenAccount.mintAddress)
            return !existingTokenTypeIds.contains(tokenType.id)
        }

        guard !newTokenAccounts.isEmpty else {
            return
        }

        let enabledWallets = newTokenAccounts.map { fullAccount in
            EnabledWallet(
                tokenQueryId: TokenQuery(blockchainType: .solana, tokenType: .spl(address: fullAccount.tokenAccount.mintAddress)).id,
                accountId: account.id,
                coinName: fullAccount.mintAccount.name,
                coinCode: fullAccount.mintAccount.symbol,
                tokenDecimals: fullAccount.mintAccount.decimals
            )
        }

        walletManager.save(enabledWallets: enabledWallets)
    }
}

extension SolanaKitManager {
    var solanaKit: SolanaKit.Kit? {
        queue.sync { _solanaKit }
    }

    func solanaKit(account: Account) throws -> SolanaKit.Kit {
        try queue.sync { try _solanaKit(account: account) }
    }

    var kitStoppedObservable: Observable<Void> {
        kitStoppedRelay.asObservable()
    }
}

extension SolanaKitManager {
    static func address(accountType: AccountType) throws -> String {
        guard let seed = accountType.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }
        return try SolanaKit.Signer.address(seed: seed).base58
    }

    static func signer(accountType: AccountType) throws -> SolanaKit.Signer {
        guard let seed = accountType.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }
        return try SolanaKit.Signer.instance(seed: seed)
    }
}
