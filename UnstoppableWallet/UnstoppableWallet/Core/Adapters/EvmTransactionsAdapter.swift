import EthereumKit
import RxSwift
import BigInt
import HsToolKit
import Erc20Kit
import UniswapKit
import MarketKit

class EvmTransactionsAdapter: BaseEvmAdapter {
    static let decimal = 18

    private let evmTransactionSource: EthereumKit.TransactionSource
    private let transactionConverter: EvmTransactionConverter

    init(evmKitWrapper: EvmKitWrapper, source: TransactionSource, baseToken: MarketKit.Token, evmTransactionSource: EthereumKit.TransactionSource, coinManager: CoinManager, evmLabelManager: EvmLabelManager) {
        self.evmTransactionSource = evmTransactionSource
        transactionConverter = EvmTransactionConverter(source: source, baseToken: baseToken, coinManager: coinManager, evmKitWrapper: evmKitWrapper, evmLabelManager: evmLabelManager)

        super.init(evmKitWrapper: evmKitWrapper, decimals: EvmAdapter.decimals)
    }

    private func coinTagName(token: MarketKit.Token) -> String {
        switch token.type {
        case .native: return TransactionTag.evmCoin
        case .eip20(let address): return address
        default: return ""
        }
    }

    private func filters(token: MarketKit.Token?, filter: TransactionTypeFilter) -> [[String]] {
        var coinFilter = [[String]]()

        if let token = token {
            coinFilter.append([coinTagName(token: token)])
        }

        switch filter {
        case .all: ()
        case .incoming:
            if let token = token {
                coinFilter.append(["\(coinTagName(token: token))_incoming"])
            } else {
                coinFilter.append(["incoming"])
            }

        case .outgoing:
            if let token = token {
                coinFilter.append(["\(coinTagName(token: token))_outgoing"])
            } else {
                coinFilter.append(["outgoing"])
            }

        case .swap: coinFilter.append(["swap"])
        case .approve: coinFilter.append(["eip20Approve"])
        }

        return coinFilter
    }

}

extension EvmTransactionsAdapter: ITransactionsAdapter {

    var transactionState: AdapterState {
        convertToAdapterState(evmSyncState: evmKit.transactionsSyncState)
    }

    var transactionStateUpdatedObservable: Observable<Void> {
        evmKit.transactionsSyncStateObservable.map { _ in () }
    }

    var explorerTitle: String {
        evmTransactionSource.name
    }

    func explorerUrl(transactionHash: String) -> String? {
        evmTransactionSource.transactionUrl(hash: transactionHash)
    }

    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter) -> Observable<[TransactionRecord]> {
        evmKit.transactionsObservable(tags: filters(token: token, filter: filter)).map { [weak self] in
            $0.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, token: MarketKit.Token?, filter: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]> {
        evmKit.transactionsSingle(tags: filters(token: token, filter: filter), fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
                }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}
