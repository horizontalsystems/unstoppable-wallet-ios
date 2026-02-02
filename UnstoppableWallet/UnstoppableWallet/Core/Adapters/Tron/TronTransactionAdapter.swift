import BigInt
import Foundation
import HsToolKit
import MarketKit
import RxSwift
import TronKit

class TronTransactionsAdapter: BaseTronAdapter {
    static let decimal = 6

    private let transactionConverter: TronTransactionConverter
    private let spamWrapper: SpamWrapper
    private let spamManager: SpamManager?

    init(tronKitWrapper: TronKitWrapper, source: TransactionSource, baseToken: MarketKit.Token, coinManager: CoinManager, spamWrapper: SpamWrapper, evmLabelManager: EvmLabelManager) {
        self.spamWrapper = spamWrapper
        spamManager = spamWrapper.spamManager(source: source)

        transactionConverter = TronTransactionConverter(
            source: source,
            baseToken: baseToken,
            coinManager: coinManager,
            tronKitWrapper: tronKitWrapper,
            evmLabelManager: evmLabelManager
        )

        super.init(tronKitWrapper: tronKitWrapper, decimals: TronAdapter.decimals)

        initializeSpamManager()
    }

    private func initializeSpamManager() {
        spamManager?.initialize(adapter: self)
    }

    private func tagQuery(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> TransactionTagQuery {
        var type: TransactionTag.TagType?
        var `protocol`: TransactionTag.TagProtocol?
        var contractAddress: TronKit.Address?

        if let token {
            switch token.type {
            case .native:
                `protocol` = .native
            case let .eip20(address):
                if let address = try? TronKit.Address(address: address) {
                    `protocol` = .eip20
                    contractAddress = address
                }
            default: ()
            }
        }

        switch filter {
        case .all: ()
        case .incoming: type = .incoming
        case .outgoing: type = .outgoing
        case .swap: type = .swap
        case .approve: type = .approve
        }

        return TransactionTagQuery(type: type, protocol: `protocol`, contractAddress: contractAddress, address: address)
    }
}

extension TronTransactionsAdapter: ITransactionsAdapter {
    var syncing: Bool {
        tronKit.syncState.syncing
    }

    var syncingObservable: Observable<Void> {
        tronKit.syncStatePublisher.asObservable().map { _ in () }
    }

    var explorerTitle: String {
        "Tronscan"
    }

    var additionalTokenQueries: [TokenQuery] {
        tronKit.tagTokens().compactMap { tagToken in
            var tokenType: TokenType?

            switch tagToken.protocol {
            case .native:
                tokenType = .native
            case .eip20:
                if let contractAddress = tagToken.contractAddress {
                    tokenType = .eip20(address: contractAddress.base58)
                }
            default:
                ()
            }

            guard let tokenType else {
                return nil
            }

            return TokenQuery(blockchainType: .tron, tokenType: tokenType)
        }
    }

    func explorerUrl(transactionHash: String) -> String? {
        switch tronKit.network {
        case .mainNet: return "https://tronscan.org/#/transaction/\(transactionHash)"
        case .nileTestnet: return "https://nile.tronscan.org/#/transaction/\(transactionHash)"
        case .shastaTestnet: return "https://shasta.tronscan.org/#/transaction/\(transactionHash)"
        }
    }

    private func handleTransactions(_ transactions: [FullTransaction]) -> [TransactionRecord] {
        // Preserve tronKit order
        let records = transactions.map { transactionConverter.transactionRecord(fromTransaction: $0) }

        // Mutates .spam in-place via reference type.
        // Internally sorts ascending for correct detection,
        // but records array keeps its original order.
        spamManager?.update(records: records)

        return records
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        let address = address.flatMap { try? TronKit.Address(address: $0) }?.hex

        return tronKit.transactionsPublisher(tagQueries: [tagQuery(token: token, filter: filter, address: address)]).asObservable()
            .map { [weak self] in

                self?.handleTransactions($0) ?? []
            }
    }

    func transactionsSingle(paginationData: String?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        let address = address.flatMap { try? TronKit.Address(address: $0) }?.hex
        let transactions = tronKit.transactions(tagQueries: [tagQuery(token: token, filter: filter, address: address)], hash: paginationData?.hs.hexData, descending: true, limit: limit)

        guard !transactions.isEmpty else {
            return .just([])
        }

        return .just(handleTransactions(transactions))
    }

    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]> {
        let transactions = tronKit.transactions(tagQueries: [], hash: paginationData?.hs.hexData, descending: false, limit: nil)

        return Single.just(transactions.compactMap { transactionConverter.transactionRecord(fromTransaction: $0) })
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

class ActivatedDepositAddress: DepositAddress {
    let isActive: Bool

    init(receiveAddress: String, isActive: Bool) {
        self.isActive = isActive
        super.init(receiveAddress)
    }
}
