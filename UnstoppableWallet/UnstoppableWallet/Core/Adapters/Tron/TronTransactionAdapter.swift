import Foundation
import TronKit
import RxSwift
import BigInt
import HsToolKit
import MarketKit

class TronTransactionsAdapter: BaseTronAdapter {
    static let decimal = 6

    private let transactionConverter: TronTransactionConverter

    init(tronKitWrapper: TronKitWrapper, source: TransactionSource, baseToken: MarketKit.Token, coinManager: CoinManager, evmLabelManager: EvmLabelManager) {
        transactionConverter = TronTransactionConverter(source: source, baseToken: baseToken, coinManager: coinManager, tronKitWrapper: tronKitWrapper, evmLabelManager: evmLabelManager)

        super.init(tronKitWrapper: tronKitWrapper, decimals: TronAdapter.decimals)
    }

    private func tagQuery(token: MarketKit.Token?, filter: TransactionTypeFilter) -> TransactionTagQuery {
        var type: TransactionTag.TagType?
        var `protocol`: TransactionTag.TagProtocol?
        var contractAddress: TronKit.Address?

        if let token = token {
            switch token.type {
                case .native:
                    `protocol` = .native
                case .eip20(let address):
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
//            case .swap: type = .swap
            case .approve: type = .approve
        }

        return TransactionTagQuery(type: type, protocol: `protocol`, contractAddress: contractAddress)
    }

}

extension TronTransactionsAdapter: ITransactionsAdapter {
    var syncing: Bool {
        tronKit.syncState.syncing
    }

    var syncingObservable: Observable<()> {
        tronKit.syncStatePublisher.asObservable().map { _ in () }
    }

    var explorerTitle: String {
        "Tronscan"
    }

    func explorerUrl(transactionHash: String) -> String? {
        switch tronKit.network {
            case .mainNet: return "https://tronscan.org/#/transaction/\(transactionHash)"
            case .nileTestnet: return "https://nile.tronscan.org/#/transaction/\(transactionHash)"
            case .shastaTestnet: return "https://shasta.tronscan.org/#/transaction/\(transactionHash)"
        }
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter) -> Observable<[TransactionRecord]> {
        tronKit.transactionsPublisher(tagQueries: [tagQuery(token: token, filter: filter)]).asObservable()
            .map { [weak self] in
                $0.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
            }
    }

    func transactionsSingle(from: TransactionRecord?, token: MarketKit.Token?, filter: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]> {
        let transactions = tronKit.transactions(tagQueries: [tagQuery(token: token, filter: filter)], fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)

        return Single.just(transactions.compactMap { transactionConverter.transactionRecord(fromTransaction: $0) })
    }

    func rawTransaction(hash: String) -> String? {
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
