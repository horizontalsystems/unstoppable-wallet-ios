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

    init(evmKitWrapper: EvmKitWrapper, source: TransactionSource, baseCoin: PlatformCoin, evmTransactionSource: EthereumKit.TransactionSource, coinManager: CoinManager) {
        self.evmTransactionSource = evmTransactionSource
        transactionConverter = EvmTransactionConverter(source: source, baseCoin: baseCoin, coinManager: coinManager, evmKitWrapper: evmKitWrapper)

        super.init(evmKitWrapper: evmKitWrapper, decimals: EvmAdapter.decimals)
    }

    private func coinTagName(coin: PlatformCoin) -> String {
        switch coin.coinType {
        case .ethereum, .binanceSmartChain, .polygon: return TransactionTag.evmCoin
        case .erc20(let address): return address
        case .bep20(let address): return address
        case .mrc20(let address): return address
        default: return ""
        }
    }

    private func filters(coin: PlatformCoin?, filter: TransactionTypeFilter) -> [[String]] {
        var coinFilter = [[String]]()

        if let coin = coin {
            coinFilter.append([coinTagName(coin: coin)])
        }

        switch filter {
        case .all: ()
        case .incoming:
            if let coin = coin {
                coinFilter.append(["\(coinTagName(coin: coin))_incoming"])
            } else {
                coinFilter.append(["incoming"])
            }

        case .outgoing:
            if let coin = coin {
                coinFilter.append(["\(coinTagName(coin: coin))_outgoing"])
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

    func transactionsObservable(coin: PlatformCoin?, filter: TransactionTypeFilter) -> Observable<[TransactionRecord]> {
        evmKit.transactionsObservable(tags: filters(coin: coin, filter: filter)).map { [weak self] in
            $0.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, coin: PlatformCoin?, filter: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]> {
        evmKit.transactionsSingle(tags: filters(coin: coin, filter: filter), fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
                }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}
