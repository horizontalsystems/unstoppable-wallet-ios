import RxSwift
import MarketKit
import HsToolKit
import EvmKit
import Eip20Kit
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

        handle(foundTokens: Array(foundTokens), suspiciousTokenTypes: Array(suspiciousTokenTypes.subtracting(foundTokens.map { $0.tokenType })), account: account, evmKit: evmKitWrapper.evmKit)
    }

    private func handle(foundTokens: [FoundToken], suspiciousTokenTypes: [TokenType], account: Account, evmKit: EvmKit.Kit) {
        guard !foundTokens.isEmpty || !suspiciousTokenTypes.isEmpty else {
            return
        }

//        print("FOUND TOKEN TYPES: \(foundTokens.count): \n\(foundTokens.map { "\($0.tokenType.id) --- \($0.tokenInfo?.tokenName) --- \($0.tokenInfo?.tokenSymbol) --- \($0.tokenInfo?.tokenDecimal)" }.joined(separator: "\n"))")
//        print("SUSPICIOUS TOKEN TYPES: \(suspiciousTokenTypes.count): \n\(suspiciousTokenTypes.map { $0.id }.joined(separator: "\n"))")

        do {
            let queries = (foundTokens.map { $0.tokenType } + suspiciousTokenTypes).map { TokenQuery(blockchainType: blockchainType, tokenType: $0) }
            let tokens = try marketKit.tokens(queries: queries)

            var tokenInfos = [TokenInfo]()

            for foundToken in foundTokens {
                if let token = tokens.first(where: { $0.type == foundToken.tokenType }) {
                    let tokenInfo = TokenInfo(
                            type: foundToken.tokenType,
                            coinName: token.coin.name,
                            coinCode: token.coin.code,
                            tokenDecimals: token.decimals
                    )

                    tokenInfos.append(tokenInfo)
                } else if let tokenInfo = foundToken.tokenInfo {
                    let tokenInfo = TokenInfo(
                            type: foundToken.tokenType,
                            coinName: tokenInfo.tokenName,
                            coinCode: tokenInfo.tokenSymbol,
                            tokenDecimals: tokenInfo.tokenDecimal
                    )

                    tokenInfos.append(tokenInfo)
                }
            }

            for tokenType in suspiciousTokenTypes {
                if let token = tokens.first(where: { $0.type == tokenType }) {
                    let tokenInfo = TokenInfo(
                            type: tokenType,
                            coinName: token.coin.name,
                            coinCode: token.coin.code,
                            tokenDecimals: token.decimals
                    )

                    tokenInfos.append(tokenInfo)
                }
            }

            handle(tokenInfos: tokenInfos, account: account, evmKit: evmKit)
        } catch {
            // do nothing
        }
    }

    private func handle(tokenInfos: [TokenInfo], account: Account, evmKit: EvmKit.Kit) {
//        print("Handle Tokens: \(tokenInfos.count)\n\(tokenInfos.map { $0.type.id }.joined(separator: " "))")

        let existingWallets = walletManager.activeWallets
        let existingTokenTypeIds = existingWallets.map { $0.token.type.id }
        let newTokenInfos = tokenInfos.filter { !existingTokenTypeIds.contains($0.type.id) }

//        print("New Tokens: \(newTokenInfos.count)")

        guard !newTokenInfos.isEmpty else {
            return
        }

//        handle(processedTokenInfos: newTokenInfos, account: account)
//        return

        let userAddress = evmKit.address
        let dataProvider = DataProvider(evmKit: evmKit)

        let singles: [Single<TokenInfo?>] = newTokenInfos.map { info in
            guard case let .eip20(address) = info.type, let contractAddress = try? EvmKit.Address(hex: address) else {
                return Single.just(nil)
            }

            return dataProvider.getBalance(contractAddress: contractAddress, address: userAddress)
                    .map { balance in
                        balance > 0 ? info : nil
                    }
                    .catchErrorJustReturn(info)
        }

        Single.zip(singles)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] tokenInfos in
                    self?.handle(processedTokenInfos: tokenInfos.compactMap { $0 }, account: account)
                })
                .disposed(by: internalDisposeBag)
    }

    private func handle(processedTokenInfos infos: [TokenInfo], account: Account) {
//        print("Processed Tokens: \(infos.count): \n\(infos.map { $0.type.id }.joined(separator: ", "))")

        guard !infos.isEmpty else {
            return
        }

        let enabledWallets = infos.map { info in
            EnabledWallet(
                    tokenQueryId: TokenQuery(blockchainType: blockchainType, tokenType: info.type).id,
                    coinSettingsId: "",
                    accountId: account.id,
                    coinName: info.coinName,
                    coinCode: info.coinCode,
                    tokenDecimals: info.tokenDecimals
            )
        }

        walletManager.save(enabledWallets: enabledWallets)
    }

}

extension EvmAccountManager {

    struct TokenInfo {
        let type: TokenType
        let coinName: String
        let coinCode: String
        let tokenDecimals: Int
    }

    struct FoundToken: Hashable {
        let tokenType: MarketKit.TokenType
        let tokenInfo: Eip20Kit.TokenInfo?

        init(tokenType: MarketKit.TokenType, tokenInfo: Eip20Kit.TokenInfo? = nil) {
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
