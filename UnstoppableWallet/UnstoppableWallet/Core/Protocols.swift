import UIKit
import RxSwift
import GRDB
import UniswapKit
import EvmKit
import ThemeKit
import Alamofire
import HsToolKit
import MarketKit
import BigInt

protocol IBaseAdapter {
    var isMainNet: Bool { get }
}

protocol IAdapter: AnyObject {
    func start()
    func stop()
    func refresh()

    var statusInfo: [(String, Any)] { get }
    var debugInfo: String { get }
}

protocol IBalanceAdapter: IBaseAdapter {
    var balanceState: AdapterState { get }
    var balanceStateUpdatedObservable: Observable<AdapterState> { get }
    var balanceData: BalanceData { get }
    var balanceDataUpdatedObservable: Observable<BalanceData> { get }
}

protocol IDepositAdapter: IBaseAdapter {
    var receiveAddress: String { get }
}

protocol ITransactionsAdapter {
    var syncing: Bool { get }
    var syncingObservable: Observable<Void> { get }
    var lastBlockInfo: LastBlockInfo? { get }
    var lastBlockUpdatedObservable: Observable<Void> { get }
    var explorerTitle: String { get }
    func explorerUrl(transactionHash: String) -> String?
    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter) -> Observable<[TransactionRecord]>
    func transactionsSingle(from: TransactionRecord?, token: MarketKit.Token?, filter: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]>
    func rawTransaction(hash: String) -> String?
}

protocol ISendBitcoinAdapter {
    var blockchainType: BlockchainType { get }
    var balanceData: BalanceData { get }
    func availableBalance(feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData]) -> Decimal
    func maximumSendAmount(pluginData: [UInt8: IBitcoinPluginData]) -> Decimal?
    func minimumSendAmount(address: String?) -> Decimal
    func validate(address: String, pluginData: [UInt8: IBitcoinPluginData]) throws
    func fee(amount: Decimal, feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData]) -> Decimal
    func sendSingle(amount: Decimal, address: String, feeRate: Int, pluginData: [UInt8: IBitcoinPluginData], sortMode: TransactionDataSortMode, logger: Logger) -> Single<Void>
}

protocol ISendDashAdapter {
    func availableBalance(address: String?) -> Decimal
    func minimumSendAmount(address: String?) -> Decimal
    func validate(address: String) throws
    func fee(amount: Decimal, address: String?) -> Decimal
    func sendSingle(amount: Decimal, address: String, sortMode: TransactionDataSortMode, logger: Logger) -> Single<Void>
}

protocol ISendEthereumAdapter {
    var evmKitWrapper: EvmKitWrapper { get }
    var balanceData: BalanceData { get }
    func transactionData(amount: BigUInt, address: EvmKit.Address) -> TransactionData
}

protocol IErc20Adapter {
    var pendingTransactions: [TransactionRecord] { get }
    func allowanceSingle(spenderAddress: EvmKit.Address, defaultBlockParameter: DefaultBlockParameter) -> Single<Decimal>
}

protocol ISendBinanceAdapter {
    var availableBalance: Decimal { get }
    var availableBinanceBalance: Decimal { get }
    func validate(address: String) throws
    var fee: Decimal { get }
    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void>
}

protocol ISendZcashAdapter {
    var availableBalance: Decimal { get }
    func validate(address: String) throws -> ZcashAdapter.AddressType
    var fee: Decimal { get }
    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void>
}

// Nft Adapters

protocol INftAdapter: AnyObject {
    var userAddress: String { get }
    var nftRecordsObservable: Observable<[NftRecord]> { get }
    var nftRecords: [NftRecord] { get }
    func nftRecord(nftUid: NftUid) -> NftRecord?
    func transferEip721TransactionData(contractAddress: String, to: EvmKit.Address, tokenId: String) -> TransactionData?
    func transferEip1155TransactionData(contractAddress: String, to: EvmKit.Address, tokenId: String, value: Decimal) -> TransactionData?
    func sync()
}

protocol INftProvider {
    var title: String { get }
    func collectionLink(providerUid: String) -> String?
    func addressMetadataSingle(blockchainType: BlockchainType, address: String) -> Single<NftAddressMetadata>
    func assetsBriefMetadataSingle(nftUids: [NftUid]) -> Single<[NftAssetBriefMetadata]>
    func extendedAssetMetadataSingle(nftUid: NftUid, providerCollectionUid: String) -> Single<(NftAssetMetadata, NftCollectionMetadata)>
    func collectionAssetsMetadataSingle(blockchainType: BlockchainType, providerCollectionUid: String, paginationData: PaginationData?) -> Single<([NftAssetMetadata], PaginationData?)>
    func collectionMetadataSingle(blockchainType: BlockchainType, providerUid: String) -> Single<NftCollectionMetadata>
    func assetEventsMetadataSingle(nftUid: NftUid, eventType: NftEventMetadata.EventType?, paginationData: PaginationData?) -> Single<([NftEventMetadata], PaginationData?)>
    func collectionEventsMetadataSingle(blockchainType: BlockchainType, providerUid: String, eventType: NftEventMetadata.EventType?, paginationData: PaginationData?) -> Single<([NftEventMetadata], PaginationData?)>
}

protocol IFeeRateProvider {
    var feeRatePriorityList: [FeeRatePriority] { get }
    var defaultFeeRatePriority: FeeRatePriority { get }
    var recommendedFeeRate: Single<Int> { get }
    var feeRateUpdatedObservable: Observable<()> { get }
    func feeRate(priority: FeeRatePriority) -> Single<Int>
}

extension IFeeRateProvider {

    var feeRateUpdatedObservable: Observable<()> {
        .just(())
    }

}

protocol ICustomRangedFeeRateProvider: IFeeRateProvider {
    var customFeeRange: ClosedRange<Int> { get }
    var step: Int { get }
}

protocol IAppManager {
    var didBecomeActiveObservable: Observable<()> { get }
    var willEnterForegroundObservable: Observable<()> { get }
}

protocol IPresentDelegate: AnyObject {
    func present(viewController: UIViewController)
    func push(viewController: UIViewController)
}

extension IPresentDelegate {

    func push(viewController: UIViewController) {
        //might be implemented by delegate
    }

}

protocol IDismissDelegate: AnyObject {
    var onUserDismissed: (() -> ())? { get set }
}

protocol Warning {}

protocol IErrorService: AnyObject {
    var error: Error? { get }
    var errorObservable: Observable<Error?> { get }
}
