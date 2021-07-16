import EthereumKit
import RxSwift
import BigInt
import HsToolKit
import Erc20Kit
import UniswapKit
import CoinKit

class EvmTransactionsAdapter: BaseEvmAdapter {
    static let decimal = 18

    init(evmKit: EthereumKit.Kit, coinManager: ICoinManager) {
        super.init(evmKit: evmKit, decimal: EvmAdapter.decimal, coinManager: coinManager)
    }

    private func filters(from coin: Coin?) -> [[String]] {
        var coinFilter = [[String]]()

        if let coin = coin {
            switch coin.type {
            case .ethereum, .binanceSmartChain: coinFilter.append(["ETH"])
            case .erc20(let address): coinFilter.append([address])
            case .bep20(let address): coinFilter.append([address])
            default: ()
            }
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

    func transactionsObservable(coin: Coin?) -> Observable<[TransactionRecord]> {
        evmKit.transactionsObservable(tags: filters(from: coin)).map { [weak self] in
            $0.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, coin: Coin?, limit: Int) -> Single<[TransactionRecord]> {
        evmKit.transactionsSingle(tags: filters(from: coin), fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
                }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}
