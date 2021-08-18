import EthereumKit
import RxSwift
import BigInt
import HsToolKit
import Erc20Kit
import UniswapKit
import CoinKit

class EvmTransactionsAdapter: BaseEvmAdapter {
    static let decimal = 18

    private let transactionConverter: EvmTransactionConverter

    init(evmKit: EthereumKit.Kit, source: TransactionSource, coinManager: ICoinManager) {
        transactionConverter = EvmTransactionConverter(source: source, coinManager: coinManager, evmKit: evmKit)

        super.init(evmKit: evmKit, decimal: EvmAdapter.decimal)
    }

    private func coinTagName(coin: Coin) -> String {
        switch coin.type {
        case .ethereum, .binanceSmartChain: return TransactionTag.evmCoin
        case .erc20(let address): return address
        case .bep20(let address): return address
        default: return ""
        }
    }

    private func filters(coin: Coin?, filter: TransactionsModule2.TypeFilter) -> [[String]] {
        var coinFilter = [[String]]()

        if let coin = coin {
            switch coin.type {
            case .ethereum, .binanceSmartChain: coinFilter.append([TransactionTag.evmCoin])
            case .erc20(let address): coinFilter.append([address])
            case .bep20(let address): coinFilter.append([address])
            default: ()
            }
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

    func transactionsObservable(coin: Coin?, filter: TransactionsModule2.TypeFilter) -> Observable<[TransactionRecord]> {
        evmKit.transactionsObservable(tags: filters(coin: coin, filter: filter)).map { [weak self] in
            $0.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, coin: Coin?, filter: TransactionsModule2.TypeFilter, limit: Int) -> Single<[TransactionRecord]> {
        evmKit.transactionsSingle(tags: filters(coin: coin, filter: filter), fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
                }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}
