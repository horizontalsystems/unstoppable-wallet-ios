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

        let contactLabelService = TransactionsContactLabelService(contactManager: App.shared.contactManager)
        let viewItemFactory = TransactionsViewItemFactory(evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)
        let viewModel = TransactionsViewModel(service: service, contactLabelService: contactLabelService, factory: viewItemFactory)
        let dataSource = TransactionsTableViewDataSource(viewModel: viewModel)

        return TransactionsViewController(viewModel: viewModel, dataSource: dataSource)
    }

    static func dataSource(token: Token) -> TransactionsTableViewDataSource {
        let rateService = HistoricalRateService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let nftMetadataService = NftMetadataService(nftMetadataManager: App.shared.nftMetadataManager)

        let service = TokenTransactionsService(
                token: token,
                adapterManager: App.shared.transactionAdapterManager,
                rateService: rateService,
                nftMetadataService: nftMetadataService
        )

        let contactLabelService = TransactionsContactLabelService(contactManager: App.shared.contactManager)
        let viewItemFactory = TransactionsViewItemFactory(evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)
        let viewModel = BaseTransactionsViewModel(service: service, contactLabelService: contactLabelService, factory: viewItemFactory)

        return TransactionsTableViewDataSource(viewModel: viewModel)
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
