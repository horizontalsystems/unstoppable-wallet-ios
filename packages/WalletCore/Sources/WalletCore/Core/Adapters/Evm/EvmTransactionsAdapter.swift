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
    private let converters: [IEvmTransactionConverter]
    private let spamManager: SpamManager?

    init(evmKitWrapper: EvmKitWrapper, source: TransactionSource, baseToken: MarketKit.Token, evmTransactionSource: EvmKit.TransactionSource, spamWrapper: SpamWrapper) {
        self.evmTransactionSource = evmTransactionSource
        spamManager = spamWrapper.spamManager(source: source)

        converters = EvmTransactionConverterFactory.converters(baseToken: baseToken, userAddress: evmKitWrapper.evmKit.address)
        super.init(evmKitWrapper: evmKitWrapper, decimals: EvmAdapter.decimals)

        initializeSpamManager()
    }

    private func record(fromTransaction fullTransaction: FullTransaction, token: MarketKit.Token?) -> TransactionRecord? {
        for converter in converters {
            if let record = converter.convert(fullTransaction: fullTransaction, token: token) {
                return record
            }
        }

        print("EvmTransactionsAdapter: converter chain produced no record for \(fullTransaction.transaction.hash.hs.hexString)")
        return nil
    }

    private func initializeSpamManager() {
        spamManager?.initialize(adapter: self)
    }

    /// Usually one query. Arc's native coin gets a second one for its ERC-20 interface: such a movement
    /// is tagged by the emitting contract rather than as native, so the coin's own history would
    /// otherwise miss it, and the interface never becomes a wallet of its own. The storage ORs the
    /// queries and selects distinct rows, so nothing is listed twice.
    ///
    /// Scoped to Arc like the relabelling in `EvmTransactionConverter`. zkSync's interface also tags
    /// the fee and refund of every contract call, which are not relabelled there, so pulling them into
    /// the ETH history would add unknown calls with the fee shown twice.
    private func tagQueries(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> [TransactionTagQuery] {
        var type: TransactionTag.TagType?
        var `protocol`: TransactionTag.TagProtocol?
        var contractAddress: EvmKit.Address?
        var nativeInterfaceAddress: EvmKit.Address?

        if let token {
            switch token.type {
            case .native:
                `protocol` = .native
                if evmKitWrapper.blockchainType == .arc, let contract = evmKitWrapper.blockchainType.nativeTokenContract {
                    nativeInterfaceAddress = try? EvmKit.Address(hex: contract.address)
                }
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
        }

        var queries = [TransactionTagQuery(type: type, protocol: `protocol`, contractAddress: contractAddress, address: address)]

        if let nativeInterfaceAddress {
            queries.append(TransactionTagQuery(type: type, protocol: .eip20, contractAddress: nativeInterfaceAddress, address: address))
        }

        return queries
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

    private func handleTransactions(_ transactions: [FullTransaction], token: MarketKit.Token?) -> [TransactionRecord] {
        // Preserve evmKit order (descending — newest first)
        let records = transactions.compactMap { record(fromTransaction: $0, token: token) }

        // Mutates .spam in-place via reference type.
        // Internally sorts ascending for correct detection,
        // but records array keeps its original order.
        spamManager?.update(records: records)

        return records
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        evmKit.transactionsObservable(tagQueries: tagQueries(token: token, filter: filter, address: address?.lowercased())).map { [weak self] in

            self?.handleTransactions($0, token: token) ?? []
        }
    }

    func transactionsSingle(paginationData: String?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        let hash = paginationData?.hs.hexData

        return evmKit.transactionsSingle(tagQueries: tagQueries(token: token, filter: filter, address: address?.lowercased()), fromHash: hash, limit: limit)
            .map { [weak self] transactions -> [TransactionRecord] in

                guard !transactions.isEmpty else {
                    return []
                }

                return self?.handleTransactions(transactions, token: token) ?? []
            }
    }

    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]> {
        let hash = paginationData?.hs.hexData
        let transactions = evmKit.allTransactionsAfter(transactionHash: hash)
        let records = transactions.compactMap { record(fromTransaction: $0, token: nil) }

        return Single.just(records)
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}
