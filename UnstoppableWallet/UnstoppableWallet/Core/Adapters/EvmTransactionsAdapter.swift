import EthereumKit
import RxSwift
import BigInt
import HsToolKit
import Erc20Kit
import UniswapKit
import MarketKit

class EvmTransactionsAdapter: BaseEvmAdapter {
    static let decimal = 18

    private let transactionConverter: EvmTransactionConverter

    init(evmKit: EthereumKit.Kit, source: TransactionSource, baseCoin: PlatformCoin, coinManager: CoinManager) {
        transactionConverter = EvmTransactionConverter(source: source, baseCoin: baseCoin, coinManager: coinManager, evmKit: evmKit)

        super.init(evmKit: evmKit, decimals: EvmAdapter.decimals)
    }

    private func coinTagName(coin: PlatformCoin) -> String {
        switch coin.coinType {
        case .ethereum, .binanceSmartChain: return TransactionTag.evmCoin
        case .erc20(let address): return address
        case .bep20(let address): return address
        default: return ""
        }
    }

    private func filters(coin: PlatformCoin?, filter: TransactionTypeFilter) -> [[String]] {
        var coinFilter = [[String]]()

        if let coin = coin {
            switch coin.coinType {
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

    var explorerTitle: String {
        switch evmKit.networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: return "etherscan.io"
        case .bscMainNet: return "bscscan.com"
        }
    }

    func explorerUrl(transactionHash: String) -> String? {
        let domain: String

        switch evmKit.networkType {
        case .ethMainNet: domain = "etherscan.io"
        case .bscMainNet: domain = "bscscan.com"
        case .ropsten: domain = "ropsten.etherscan.io"
        case .rinkeby: domain = "rinkeby.etherscan.io"
        case .kovan: domain = "kovan.etherscan.io"
        case .goerli: domain = "goerli.etherscan.io"
        }

        return "https://\(domain)/tx/" + transactionHash
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
