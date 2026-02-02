import BigInt
import Eip20Kit
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import RxSwift
import UniswapKit

class EvmTransactionsAdapter: BaseEvmAdapter {
    static let decimal = 18

    private let evmTransactionSource: EvmKit.TransactionSource
    private let transactionConverter: EvmTransactionConverter
    private let spamManager: SpamManager?

    init(evmKitWrapper: EvmKitWrapper, source: TransactionSource, baseToken: MarketKit.Token, evmTransactionSource: EvmKit.TransactionSource, coinManager: CoinManager, spamWrapper: SpamWrapper, evmLabelManager: EvmLabelManager) {
        self.evmTransactionSource = evmTransactionSource
        spamManager = spamWrapper.spamManager(source: source)

        transactionConverter = EvmTransactionConverter(
            source: source,
            baseToken: baseToken,
            coinManager: coinManager,
            blockchainType: evmKitWrapper.blockchainType,
            userAddress: evmKitWrapper.evmKit.address,
            evmLabelManager: evmLabelManager
        )

        super.init(evmKitWrapper: evmKitWrapper, decimals: EvmAdapter.decimals)

        initializeSpamManager()
    }

    private func initializeSpamManager() {
        spamManager?.initialize(adapter: self)
    }

    private func tagQuery(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> TransactionTagQuery {
        var type: TransactionTag.TagType?
        var `protocol`: TransactionTag.TagProtocol?
        var contractAddress: EvmKit.Address?

        if let token {
            switch token.type {
            case .native:
                `protocol` = .native
            case let .eip20(address):
                if let address = try? EvmKit.Address(hex: address) {
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

extension EvmTransactionsAdapter: ITransactionsAdapter {
    var syncing: Bool {
        evmKit.transactionsSyncState.syncing
    }

    var syncingObservable: Observable<Void> {
        evmKit.transactionsSyncStateObservable.map { _ in () }
    }

    var explorerTitle: String {
        evmTransactionSource.name
    }

    var additionalTokenQueries: [TokenQuery] {
        evmKit.tagTokens().compactMap { tagToken in
            var tokenType: TokenType?

            switch tagToken.protocol {
            case .native:
                tokenType = .native
            case .eip20:
                if let contractAddress = tagToken.contractAddress {
                    tokenType = .eip20(address: contractAddress.hex)
                }
            default:
                ()
            }

            guard let tokenType else {
                return nil
            }

            return TokenQuery(blockchainType: evmKitWrapper.blockchainType, tokenType: tokenType)
        }
    }

    func explorerUrl(transactionHash: String) -> String? {
        evmTransactionSource.transactionUrl(hash: transactionHash)
    }

    private func handleTransactions(_ transactions: [FullTransaction]) -> [TransactionRecord] {
        // Preserve evmKit order (descending — newest first)
        let records = transactions.map { transactionConverter.transactionRecord(fromTransaction: $0) }

        // Mutates .spam in-place via reference type.
        // Internally sorts ascending for correct detection,
        // but records array keeps its original order.
        spamManager?.update(records: records)

        return records
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        print("EmvTxAdapter: get Observable!")
        return evmKit.transactionsObservable(tagQueries: [tagQuery(token: token, filter: filter, address: address?.lowercased())]).map { [weak self] in

            print("EmvTxAdapter|TxObservable: got \($0.count) txs")
            return self?.handleTransactions($0) ?? []
        }
    }

    func transactionsSingle(paginationData: String?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        let hash = paginationData?.hs.hexData

        return evmKit.transactionsSingle(tagQueries: [tagQuery(token: token, filter: filter, address: address?.lowercased())], fromHash: hash, limit: limit)
            .map { [weak self] transactions -> [TransactionRecord] in
                print("EmvTxAdapter|TxSingle: got \(transactions.count) txs")

                guard !transactions.isEmpty else {
                    return []
                }

                return self?.handleTransactions(transactions) ?? []
            }
    }

    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]> {
        let hash = paginationData?.hs.hexData
        let transactions = evmKit.allTransactionsAfter(transactionHash: hash)
        let records = transactions.compactMap { transactionConverter.transactionRecord(fromTransaction: $0) }

        return Single.just(records)
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}
