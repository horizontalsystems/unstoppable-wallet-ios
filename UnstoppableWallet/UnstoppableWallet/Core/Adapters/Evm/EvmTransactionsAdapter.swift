import Foundation
import EvmKit
import RxSwift
import BigInt
import HsToolKit
import Eip20Kit
import UniswapKit
import MarketKit

class EvmTransactionsAdapter: BaseEvmAdapter {
    static let decimal = 18

    private let evmTransactionSource: EvmKit.TransactionSource
    private let transactionConverter: EvmTransactionConverter

    init(evmKitWrapper: EvmKitWrapper, source: TransactionSource, baseToken: MarketKit.Token, evmTransactionSource: EvmKit.TransactionSource, coinManager: CoinManager, evmLabelManager: EvmLabelManager) {
        self.evmTransactionSource = evmTransactionSource
        transactionConverter = EvmTransactionConverter(source: source, baseToken: baseToken, coinManager: coinManager, evmKitWrapper: evmKitWrapper, evmLabelManager: evmLabelManager)

        super.init(evmKitWrapper: evmKitWrapper, decimals: EvmAdapter.decimals)
    }

    private func tagQuery(token: MarketKit.Token?, filter: TransactionTypeFilter) -> TransactionTagQuery {
        var type: TransactionTag.TagType?
        var `protocol`: TransactionTag.TagProtocol?
        var contractAddress: EvmKit.Address?

        if let token = token {
            switch token.type {
            case .native:
                `protocol` = .native
            case .eip20(let address):
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

        return TransactionTagQuery(type: type, protocol: `protocol`, contractAddress: contractAddress)
    }

}

extension EvmTransactionsAdapter: ITransactionsAdapter {
    var syncing: Bool {
        evmKit.transactionsSyncState.syncing
    }

    var syncingObservable: Observable<()> {
        evmKit.transactionsSyncStateObservable.map { _ in () }
    }

    var explorerTitle: String {
        evmTransactionSource.name
    }

    func explorerUrl(transactionHash: String) -> String? {
        evmTransactionSource.transactionUrl(hash: transactionHash)
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter) -> Observable<[TransactionRecord]> {
        evmKit.transactionsObservable(tagQueries: [tagQuery(token: token, filter: filter)]).map { [weak self] in
            $0.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, token: MarketKit.Token?, filter: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]> {
        evmKit.transactionsSingle(tagQueries: [tagQuery(token: token, filter: filter)], fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
                }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}
