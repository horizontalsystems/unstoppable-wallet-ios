import UIKit
import SectionsTableView
import MarketKit

struct NftActivityModule {

    static func viewController(eventListType: NftEventListType, defaultEventType: NftEventMetadata.EventType? = .sale) -> NftActivityViewController {
        let coinPriceService = WalletCoinPriceService(tag: "nft-activity", currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftActivityService(eventListType: eventListType, defaultEventType: defaultEventType, nftMetadataManager: App.shared.nftMetadataManager, coinPriceService: coinPriceService)
        let viewModel = NftActivityViewModel(service: service)

        let cellFactory: INftActivityCellFactory
        switch eventListType {
        case .collection(_, let providerUid): cellFactory = NftCollectionCellFactory(providerCollectionUid: providerUid)
        case .asset: cellFactory = NftAssetCellFactory()
        }

        return NftActivityViewController(viewModel: viewModel, cellFactory: cellFactory)
    }

    enum NftEventListType {
        case collection(blockchainType: BlockchainType, providerUid: String)
        case asset(nftUid: NftUid)
    }

}

protocol INftActivityCellFactory: AnyObject {
    var parentNavigationController: UINavigationController? { get set }
    func row(tableView: UITableView, viewItem: NftActivityViewModel.EventViewItem, index: Int, onReachBottom: (() -> ())?) -> RowProtocol
}
