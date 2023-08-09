import RxSwift
import MarketKit
import HsToolKit
import TronKit

class TronAccountManager {
    private let blockchainType: BlockchainType = .tron
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let marketKit: MarketKit.Kit
    private let tronKitManager: TronKitManager
    private let evmAccountRestoreStateManager: EvmAccountRestoreStateManager

    private let disposeBag = DisposeBag()
    private var internalDisposeBag = DisposeBag()

    init(accountManager: AccountManager, walletManager: WalletManager, marketKit: MarketKit.Kit, tronKitManager: TronKitManager, evmAccountRestoreStateManager: EvmAccountRestoreStateManager) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.marketKit = marketKit
        self.tronKitManager = tronKitManager
        self.evmAccountRestoreStateManager = evmAccountRestoreStateManager

        subscribe(ConcurrentDispatchQueueScheduler(qos: .utility), disposeBag, tronKitManager.tronKitCreatedObservable) { [weak self] in self?.handleTronKitCreated() }
    }

    private func handleTronKitCreated() {
        internalDisposeBag = DisposeBag()

        subscribeToTransactions()
    }

    private func subscribeToTransactions() {
        guard let tronKitWrapper = tronKitManager.tronKitWrapper else {
            return
        }

        tronKitWrapper.tronKit.allTransactionsPublisher.asObservable()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
            .subscribe(onNext: { [weak self] fullTransactions, initial in
                self?.handle(fullTransactions: fullTransactions, initial: initial)
            })
            .disposed(by: internalDisposeBag)
    }

    private func handle(fullTransactions: [FullTransaction], initial: Bool) {
        guard let account = accountManager.activeAccount else {
            return
        }

        if initial, account.origin == .restored, !account.watchAccount, !evmAccountRestoreStateManager.isRestored(account: account, blockchainType: blockchainType) {
            return
        }

        guard let tronKitWrapper = tronKitManager.tronKitWrapper else {
            return
        }

        let address = tronKitWrapper.tronKit.address

        var foundTokens = Set<FoundToken>()
        var suspiciousTokenTypes = Set<TokenType>()

        for fullTransaction in fullTransactions {
            switch fullTransaction.decoration {
                case let decoration as NativeTransactionDecoration:
                    if let transfer = decoration.contract as? TransferContract, transfer.ownerAddress != address {
                        foundTokens.insert(FoundToken(tokenType: .native))
                    }

                case let decoration as UnknownTransactionDecoration:
                    if decoration.internalTransactions.contains(where: { $0.to == address }) {
                        foundTokens.insert(FoundToken(tokenType: .native))
                    }

                    for event in decoration.events {
                        guard let transferEvent = event as? Trc20TransferEvent else {
                            continue
                        }

                        if transferEvent.to == address {
                            let tokenType: TokenType = .eip20(address: transferEvent.contractAddress.base58)
                            if let fromAddress = decoration.fromAddress, fromAddress == address {
                                foundTokens.insert(FoundToken(tokenType: tokenType, tokenInfo: transferEvent.tokenInfo))
                            } else {
                                suspiciousTokenTypes.insert(tokenType)
                            }
                        }
                    }

                default: ()
            }
        }

        handle(foundTokens: Array(foundTokens), suspiciousTokenTypes: Array(suspiciousTokenTypes.subtracting(foundTokens.map { $0.tokenType })), account: account, tronKit: tronKitWrapper.tronKit)
    }

    private func handle(foundTokens: [FoundToken], suspiciousTokenTypes: [TokenType], account: Account, tronKit: TronKit.Kit) {
        guard !foundTokens.isEmpty || !suspiciousTokenTypes.isEmpty else {
            return
        }

        let queries = (foundTokens.map { $0.tokenType } + suspiciousTokenTypes).map { TokenQuery(blockchainType: blockchainType, tokenType: $0) }

        guard let tokens = try? marketKit.tokens(queries: queries) else {
            return
        }

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

        handle(tokenInfos: tokenInfos, account: account, tronKit: tronKit)
    }

    private func handle(tokenInfos: [TokenInfo], account: Account, tronKit: TronKit.Kit) {
        let existingWallets = walletManager.activeWallets
        let existingTokenTypeIds = existingWallets.map { $0.token.type.id }
        let newTokenInfos = tokenInfos.filter { !existingTokenTypeIds.contains($0.type.id) }

        guard !newTokenInfos.isEmpty else {
            return
        }

        let tokenInfos = newTokenInfos.compactMap { info -> TokenInfo? in
            guard case let .eip20(address) = info.type, let contractAddress = try? TronKit.Address(address: address) else {
                return nil
            }

            return tronKit.trc20Balance(contractAddress: contractAddress) > 0 ? info : nil
        }

        handle(processedTokenInfos: tokenInfos.compactMap { $0 }, account: account)
    }

    private func handle(processedTokenInfos infos: [TokenInfo], account: Account) {
        guard !infos.isEmpty else {
            return
        }

        let enabledWallets = infos.map { info in
            EnabledWallet(
                tokenQueryId: TokenQuery(blockchainType: blockchainType, tokenType: info.type).id,
                accountId: account.id,
                coinName: info.coinName,
                coinCode: info.coinCode,
                tokenDecimals: info.tokenDecimals
            )
        }

        walletManager.save(enabledWallets: enabledWallets)
    }

}

extension TronAccountManager {

    struct TokenInfo {
        let type: TokenType
        let coinName: String
        let coinCode: String
        let tokenDecimals: Int
    }

    struct FoundToken: Hashable {
        let tokenType: MarketKit.TokenType
        let tokenInfo: TronKit.TokenInfo?

        init(tokenType: MarketKit.TokenType, tokenInfo: TronKit.TokenInfo? = nil) {
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
