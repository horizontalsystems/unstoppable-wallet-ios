import RxSwift
import MarketKit
import HsToolKit
import EthereumKit
import Erc20Kit
import UniswapKit
import OneInchKit

class EvmAccountManager {
    private let blockchainType: BlockchainType
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let marketKit: MarketKit.Kit
    private let evmKitManager: EvmKitManager
    private let evmAccountRestoreStateManager: EvmAccountRestoreStateManager

    private let disposeBag = DisposeBag()
    private var internalDisposeBag = DisposeBag()

    init(blockchainType: BlockchainType, accountManager: AccountManager, walletManager: WalletManager, marketKit: MarketKit.Kit, evmKitManager: EvmKitManager, evmAccountRestoreStateManager: EvmAccountRestoreStateManager) {
        self.blockchainType = blockchainType
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.marketKit = marketKit
        self.evmKitManager = evmKitManager
        self.evmAccountRestoreStateManager = evmAccountRestoreStateManager

        subscribe(ConcurrentDispatchQueueScheduler(qos: .utility), disposeBag, evmKitManager.evmKitCreatedObservable) { [weak self] in self?.handleEvmKitCreated() }
    }

    private func handleEvmKitCreated() {
        internalDisposeBag = DisposeBag()

        subscribeToTransactions()
    }

    private func subscribeToTransactions() {
        guard let evmKitWrapper = evmKitManager.evmKitWrapper else {
            return
        }

//        print("Subscribe: \(evmKitWrapper.evmKit.networkType)")

        evmKitWrapper.evmKit.allTransactionsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] fullTransactions, initial in
                    self?.handle(fullTransactions: fullTransactions, initial: initial)
                })
                .disposed(by: internalDisposeBag)
    }

    private func handle(fullTransactions: [FullTransaction], initial: Bool) {
//        print("Tx Sync: \(blockchainType): full transactions: \(fullTransactions.count); initial: \(initial)")

        guard let account = accountManager.activeAccount else {
            return
        }

        if initial, account.origin == .restored, !account.watchAccount, !evmAccountRestoreStateManager.isRestored(account: account, blockchainType: blockchainType) {
            return
        }

        guard let evmKitWrapper = evmKitManager.evmKitWrapper else {
            return
        }

        let address = evmKitWrapper.evmKit.address

        var foundTokens = Set<FoundToken>()
        var suspiciousTokenTypes = Set<TokenType>()

        for fullTransaction in fullTransactions {
            switch fullTransaction.decoration {
            case is IncomingDecoration:
                foundTokens.insert(FoundToken(tokenType: .native))

            case let decoration as SwapDecoration:
                switch decoration.tokenOut {
                case .eip20Coin(let address, _): foundTokens.insert(FoundToken(tokenType: .eip20(address: address.hex), tokenInfo: decoration.tokenOut.tokenInfo))
                default: ()
                }

            case let decoration as OneInchSwapDecoration:
                switch decoration.tokenOut {
                case .eip20Coin(let address, _): foundTokens.insert(FoundToken(tokenType: .eip20(address: address.hex), tokenInfo: decoration.tokenOut.tokenInfo))
                default: ()
                }

            case let decoration as OneInchUnoswapDecoration:
                if let tokenOut = decoration.tokenOut {
                    switch tokenOut {
                    case .eip20Coin(let address, _): foundTokens.insert(FoundToken(tokenType: .eip20(address: address.hex), tokenInfo: tokenOut.tokenInfo))
                    default: ()
                    }
                }

            case let decoration as UnknownTransactionDecoration:
                if decoration.internalTransactions.contains(where: { $0.to == address }) {
                    foundTokens.insert(FoundToken(tokenType: .native))
                }

                for eventInstance in decoration.eventInstances {
                    guard let transferEventInstance = eventInstance as? TransferEventInstance else {
                        continue
                    }

                    if transferEventInstance.to == address {
                        let tokenType: TokenType = .eip20(address: transferEventInstance.contractAddress.hex)
                        if let fromAddress = decoration.fromAddress, fromAddress == address {
                            foundTokens.insert(FoundToken(tokenType: tokenType, tokenInfo: transferEventInstance.tokenInfo))
                        } else {
                            suspiciousTokenTypes.insert(tokenType)
                        }
                    }
                }

            default: ()
            }
        }

        handle(foundTokens: Array(foundTokens), suspiciousTokenTypes: Array(suspiciousTokenTypes.subtracting(foundTokens.map { $0.tokenType })), account: account)
    }

    private func handle(foundTokens: [FoundToken], suspiciousTokenTypes: [TokenType], account: Account) {
        guard !foundTokens.isEmpty || !suspiciousTokenTypes.isEmpty else {
            return
        }

//        print("FOUND TOKEN TYPES: \(foundTokens.count): \n\(foundTokens.map { "\($0.tokenType.id) --- \($0.tokenInfo?.tokenName) --- \($0.tokenInfo?.tokenSymbol) --- \($0.tokenInfo?.tokenDecimal)" }.joined(separator: "\n"))")
//        print("SUSPICIOUS TOKEN TYPES: \(suspiciousTokenTypes.count): \n\(suspiciousTokenTypes.map { $0.id }.joined(separator: "\n"))")

        do {
            let queries = (foundTokens.map { $0.tokenType } + suspiciousTokenTypes).map { TokenQuery(blockchainType: blockchainType, tokenType: $0) }
            let tokens = try marketKit.tokens(queries: queries)

            var enabledWallets = [EnabledWallet]()

            for foundToken in foundTokens {
                let tokenQuery = TokenQuery(blockchainType: blockchainType, tokenType: foundToken.tokenType)

                if let token = tokens.first(where: { $0.type == foundToken.tokenType }) {
                    let enabledWallet = EnabledWallet(
                            tokenQueryId: tokenQuery.id,
                            coinSettingsId: "",
                            accountId: account.id,
                            coinName: token.coin.name,
                            coinCode: token.coin.code,
                            tokenDecimals: token.decimals
                    )

                    enabledWallets.append(enabledWallet)
                } else if let tokenInfo = foundToken.tokenInfo {
                    let enabledWallet = EnabledWallet(
                            tokenQueryId: tokenQuery.id,
                            coinSettingsId: "",
                            accountId: account.id,
                            coinName: tokenInfo.tokenName,
                            coinCode: tokenInfo.tokenSymbol,
                            tokenDecimals: tokenInfo.tokenDecimal
                    )

                    enabledWallets.append(enabledWallet)
                }
            }

            for tokenType in suspiciousTokenTypes {
                if let token = tokens.first(where: { $0.type == tokenType }) {
                    let enabledWallet = EnabledWallet(
                            tokenQueryId: TokenQuery(blockchainType: blockchainType, tokenType: tokenType).id,
                            coinSettingsId: "",
                            accountId: account.id,
                            coinName: token.coin.name,
                            coinCode: token.coin.code,
                            tokenDecimals: token.decimals
                    )

                    enabledWallets.append(enabledWallet)
                }
            }

            handle(enabledWallets: enabledWallets, account: account)
        } catch {
            // do nothing
        }
    }

    private func handle(enabledWallets: [EnabledWallet], account: Account) {
        guard !enabledWallets.isEmpty else {
            return
        }

        let existingWallets = walletManager.activeWallets
        let existingTokenQueryIds = existingWallets.map { $0.token.tokenQuery.id }
        let newEnabledWallets = enabledWallets.filter { !existingTokenQueryIds.contains($0.tokenQueryId) }

//        print("New wallets: \(newEnabledWallets.count): \n\(newEnabledWallets.map { $0.tokenQueryId }.joined(separator: ", "))")

        guard !newEnabledWallets.isEmpty else {
            return
        }

        walletManager.save(enabledWallets: newEnabledWallets)
    }

}

extension EvmAccountManager {

    struct FoundToken: Hashable {
        let tokenType: MarketKit.TokenType
        let tokenInfo: Erc20Kit.TokenInfo?

        init(tokenType: MarketKit.TokenType, tokenInfo: Erc20Kit.TokenInfo? = nil) {
            self.tokenType = tokenType
            self.tokenInfo = tokenInfo
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(tokenType)
        }

        static func ==(lhs: FoundToken, rhs: FoundToken) -> Bool {
            lhs.tokenType == rhs.tokenType
        }
    }

}
