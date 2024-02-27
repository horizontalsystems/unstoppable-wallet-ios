import MarketKit
import RxSwift
import UIKit

enum TransactionsModule {
    static func viewController() -> UIViewController {
        let rateService = HistoricalRateService(marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager)
        let nftMetadataService = NftMetadataService(nftMetadataManager: App.shared.nftMetadataManager)

        let filterService = TransactionFilterService()

        let service = TransactionsService(
            filterService: filterService,
            walletManager: App.shared.walletManager,
            adapterManager: App.shared.transactionAdapterManager,
            rateService: rateService,
            nftMetadataService: nftMetadataService,
            balanceHiddenManager: App.shared.balanceHiddenManager
        )

        let contactLabelService = TransactionsContactLabelService(contactManager: App.shared.contactManager)
        let viewItemFactory = TransactionsViewItemFactory(evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)
        let viewModel = TransactionsViewModel(service: service, contactLabelService: contactLabelService, factory: viewItemFactory)
        let dataSource = TransactionsTableViewDataSource(viewModel: viewModel)

        return TransactionsViewController(viewModel: viewModel, dataSource: dataSource, transactionFilterService: filterService)
    }

    static func dataSource(token: Token) -> TransactionsTableViewDataSource {
        let rateService = HistoricalRateService(marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager)
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

    static func < (lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        lhs.record < rhs.record
    }

    static func == (lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        lhs.record == rhs.record
    }
}

struct TransactionFilter: Equatable {
    private(set) var blockchain: Blockchain?
    private(set) var token: Token?
    private(set) var contact: Contact?
    var scamFilterEnabled: Bool

    init() {
        blockchain = nil
        token = nil
        contact = nil
        scamFilterEnabled = true
    }

    var hasChanges: Bool {
        blockchain != nil || token != nil || contact != nil || !scamFilterEnabled
    }

    private mutating func updateContact() {
        guard let blockchain, let contact else {
            return
        }

        if !TransactionFilterService.allowedBlockchainForContacts.contains(blockchain.type) {
            self.contact = nil
        }

        if !contact.addresses.contains(where: { $0.blockchainUid == blockchain.uid}) {
            self.contact = nil
        }
    }

    mutating func set(blockchain: Blockchain?) {
        self.blockchain = blockchain
        token = nil

        updateContact()
    }

    mutating func set(token: Token?) {
        self.token = token
        blockchain = token?.blockchain

        updateContact()
    }

    mutating func set(contact: Contact?) {
        self.contact = contact
    }

    mutating func reset() {
        blockchain = nil
        token = nil
        contact = nil
        scamFilterEnabled = true
    }
}
