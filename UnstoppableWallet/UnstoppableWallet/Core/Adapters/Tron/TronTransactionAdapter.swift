import BigInt
import Foundation
import HsToolKit
import MarketKit
import RxSwift
import TronKit

class TronTransactionsAdapter: BaseTronAdapter {
    static let decimal = 6

    private let transactionConverter: TronTransactionConverter

    init(tronKitWrapper: TronKitWrapper, source: TransactionSource, baseToken: MarketKit.Token, coinManager: CoinManager, evmLabelManager: EvmLabelManager) {
        transactionConverter = TronTransactionConverter(source: source, baseToken: baseToken, coinManager: coinManager, tronKitWrapper: tronKitWrapper, evmLabelManager: evmLabelManager)

        super.init(tronKitWrapper: tronKitWrapper, decimals: TronAdapter.decimals)
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

            return TokenQuery(blockchainType: tronKitWrapper.blockchainType, tokenType: tokenType)
        }
    }

    func explorerUrl(transactionHash: String) -> String? {
        switch tronKit.network {
        case .mainNet: return "https://tronscan.org/#/transaction/\(transactionHash)"
        case .nileTestnet: return "https://nile.tronscan.org/#/transaction/\(transactionHash)"
        case .shastaTestnet: return "https://shasta.tronscan.org/#/transaction/\(transactionHash)"
        }
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        let address = address.flatMap { try? TronKit.Address(address: $0) }?.hex
        return tronKit.transactionsPublisher(tagQueries: [tagQuery(token: token, filter: filter, address: address)]).asObservable()
            .map { [weak self] in
                $0.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
            }
    }

    func transactionsSingle(from: TransactionRecord?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        let address = address.flatMap { try? TronKit.Address(address: $0) }?.hex
        let transactions = tronKit.transactions(tagQueries: [tagQuery(token: token, filter: filter, address: address)], fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)

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
