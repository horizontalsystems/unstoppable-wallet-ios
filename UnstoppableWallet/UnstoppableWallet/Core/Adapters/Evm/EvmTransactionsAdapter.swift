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

    init(evmKitWrapper: EvmKitWrapper, source: TransactionSource, baseToken: MarketKit.Token, evmTransactionSource: EvmKit.TransactionSource, coinManager: CoinManager, evmLabelManager: EvmLabelManager) {
        self.evmTransactionSource = evmTransactionSource
        transactionConverter = EvmTransactionConverter(source: source, baseToken: baseToken, coinManager: coinManager, evmKitWrapper: evmKitWrapper, evmLabelManager: evmLabelManager)

        super.init(evmKitWrapper: evmKitWrapper, decimals: EvmAdapter.decimals)
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

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]> {
        evmKit.transactionsObservable(tagQueries: [tagQuery(token: token, filter: filter, address: address?.lowercased())]).map { [weak self] in
            $0.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]> {
        evmKit.transactionsSingle(tagQueries: [tagQuery(token: token, filter: filter, address: address?.lowercased())], fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)
            .map { [weak self] transactions -> [TransactionRecord] in
                transactions.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
            }
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}
