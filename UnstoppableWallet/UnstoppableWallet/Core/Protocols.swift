import Alamofire
import BigInt
import BitcoinCore
import Combine
import EvmKit
import GRDB
import HsToolKit
import MarketKit
import RxSwift
import TonKit
import TonSwift
import TronKit
import UIKit
import UniswapKit
import ZcashLightClientKit

protocol IBaseAdapter: AnyObject {
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
    var receiveAddress: DepositAddress { get }
    var receiveAddressStatus: DataStatus<DepositAddress> { get }
    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> { get }
    func usedAddresses(change: Bool) -> [UsedAddress]
}

extension IDepositAdapter {
    var receiveAddressStatus: DataStatus<DepositAddress> {
        .completed(receiveAddress)
    }

    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        Just(receiveAddressStatus).eraseToAnyPublisher()
    }

    func usedAddresses(change _: Bool) -> [UsedAddress] { [] }
}

protocol ITransactionsAdapter {
    var syncing: Bool { get }
    var syncingObservable: Observable<Void> { get }
    var lastBlockInfo: LastBlockInfo? { get }
    var lastBlockUpdatedObservable: Observable<Void> { get }
    var explorerTitle: String { get }
    var additionalTokenQueries: [TokenQuery] { get }
    func explorerUrl(transactionHash: String) -> String?
    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]>
    func transactionsSingle(paginationData: String?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]>
    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]>
    func rawTransaction(hash: String) -> String?
}

protocol ISendBitcoinAdapter {
    var blockchainType: BlockchainType { get }
    var balanceData: BalanceData { get }
    func availableBalance(params: SendParameters) -> Decimal
    func maximumSendAmount(pluginData: [UInt8: IBitcoinPluginData]) -> Decimal?
    func minimumSendAmount(params: SendParameters) -> Decimal
    func validate(address: String, pluginData: [UInt8: IPluginData]) throws
    func unspentOutputs(filters: UtxoFilters) -> [UnspentOutputInfo]
    func sendInfo(params: SendParameters) throws -> SendInfo
    func sendSingle(params: SendParameters, logger: HsToolKit.Logger) -> Single<Void>
    func convertToSatoshi(value: Decimal) -> Int
    func convertToKitSortMode(sort: TransactionDataSortMode) -> TransactionDataSortType
}

protocol ISendDashAdapter {
    func availableBalance(address: String?) -> Decimal
    func minimumSendAmount(address: String?) -> Decimal
    func validate(address: String) throws
    func fee(amount: Decimal, address: String?) -> Decimal
    func sendSingle(amount: Decimal, address: String, sortMode: TransactionDataSortMode, logger: HsToolKit.Logger) -> Single<Void>
}

protocol ISendEthereumAdapter {
    var evmKitWrapper: EvmKitWrapper { get }
    var balanceData: BalanceData { get }
    func transactionData(amount: BigUInt, address: EvmKit.Address) -> TransactionData
}

protocol ISendTronAdapter {
    var tronKitWrapper: TronKitWrapper { get }
    var balanceData: BalanceData { get }
    func contract(amount: BigUInt, address: TronKit.Address, memo: String?) -> TronKit.Contract
    func accountActive(address: TronKit.Address) async -> Bool
}

protocol ISendTonAdapter {
    func transferData(recipient: FriendlyAddress, amount: TonAdapter.SendAmount, comment: String?) throws -> TransferData
}

protocol IAllowanceAdapter {
    var pendingTransactions: [TransactionRecord] { get }
    func allowance(spenderAddress: Address, defaultBlockParameter: BlockParameter) async throws -> Decimal
}

enum BlockParameter {
    case blockNumber(value: Int)
    case earliest
    case latest
    case pending
}

protocol IApproveDataProvider {
    func approveSendData(token: MarketKit.Token, spenderAddress: Address, amount: BigUInt) throws -> SendData
}

protocol ISendZcashAdapter {
    var availableBalance: Decimal { get }
    var areFundsSpendable: Bool { get }
    func validate(address: String, checkSendToSelf: Bool) throws -> ZcashAdapter.AddressType
    func sendProposal(amount: Decimal, address: Recipient, memo: Memo?) async throws -> Proposal
    func sendSingle(amount: Decimal, address: Recipient, memo: Memo?) -> Single<Void>
    func send(proposal: Proposal) async throws
    func recipient(from stringEncodedAddress: String) -> Recipient?
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
}

protocol INftEventProvider {
    func assetEventsMetadataSingle(nftUid: NftUid, eventType: NftEventMetadata.EventType?, paginationData: PaginationData?) -> Single<([NftEventMetadata], PaginationData?)>
    func collectionEventsMetadataSingle(blockchainType: BlockchainType, contractAddress: String, eventType: NftEventMetadata.EventType?, paginationData: PaginationData?) -> Single<([NftEventMetadata], PaginationData?)>
}

protocol IFeeRateProvider {
    func feeRates() async throws -> FeeRateProvider.FeeRates
}

protocol IAppManager {
    var didBecomeActiveObservable: Observable<Void> { get }
    var willEnterForegroundObservable: Observable<Void> { get }
}

protocol IPresentDelegate: AnyObject {
    func present(viewController: UIViewController)
    func push(viewController: UIViewController)
}

extension IPresentDelegate {
    func push(viewController _: UIViewController) {
        // might be implemented by delegate
    }
}

protocol Warning {
    var titledCaution: TitledCaution { get }
    var caution: CautionNew { get }
}

extension Warning {
    var titledCaution: TitledCaution { TitledCaution(title: "", text: "", type: .warning) }
    var caution: CautionNew {
        let caution = titledCaution
        return .init(title: caution.title, text: caution.text, type: caution.type)
    }
}

protocol IErrorService: AnyObject {
    var error: Error? { get }
    var errorObservable: Observable<Error?> { get }
}

protocol IDynamicHeightCellDelegate: AnyObject {
    func onChangeHeight()
}
