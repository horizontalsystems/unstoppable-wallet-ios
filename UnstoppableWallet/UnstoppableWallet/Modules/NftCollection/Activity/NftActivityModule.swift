import MarketKit
import SectionsTableView
import UIKit

struct NftActivityModule {
    static func viewController(eventListType: NftEventListType, defaultEventType: NftEvent.EventType? = .sale) -> NftActivityViewController {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftActivityService(eventListType: eventListType, defaultEventType: defaultEventType, marketKit: App.shared.marketKit, coinPriceService: coinPriceService)
        let viewModel = NftActivityViewModel(service: service)

        let cellFactory: INftActivityCellFactory
        switch eventListType {
        case .collection: cellFactory = NftCollectionCellFactory()
        case .asset: cellFactory = NftAssetCellFactory()
        }

        return NftActivityViewController(viewModel: viewModel, cellFactory: cellFactory)
    }

    enum NftEventListType {
        case collection(uid: String)
        case asset(contractAddress: String, tokenId: String)
    }
}

protocol INftActivityCellFactory: AnyObject {
    var parentNavigationController: UINavigationController? { get set }
    func row(tableView: UITableView, viewItem: NftActivityViewModel.EventViewItem, index: Int, onReachBottom: (() -> ())?) -> RowProtocol
}