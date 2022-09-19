import UIKit
import RxSwift
import CurrencyKit
import MarketKit

struct TransactionsModule {

    static func viewController() -> UIViewController {
        let rateService = HistoricalRateService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let nftMetadataService = NftMetadataService(nftMetadataManager: App.shared.nftMetadataManager)

        let service = TransactionsService(
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.transactionAdapterManager,
                rateService: rateService,
                nftMetadataService: nftMetadataService
        )

        let viewItemFactory = TransactionsViewItemFactory(evmLabelManager: App.shared.evmLabelManager)
        let viewModel = TransactionsViewModel(service: service, factory: viewItemFactory)
        let viewController = TransactionsViewController(viewModel: viewModel)

        return viewController
    }

}

struct TransactionItem: Comparable {
    var record: TransactionRecord
    var status: TransactionStatus
    var lockState: TransactionLockState?

    static func <(lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        lhs.record < rhs.record
    }

    static func ==(lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        lhs.record == rhs.record
    }
}
