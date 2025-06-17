import MarketKit
import RxSwift
import SwiftUI
import UIKit

enum TransactionsModule {
    static func viewController() -> UIViewController {
        let rateService = HistoricalRateService(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager)
        let nftMetadataService = NftMetadataService(nftMetadataManager: Core.shared.nftMetadataManager)

        let service = TransactionsService(
            walletManager: Core.shared.walletManager,
            adapterManager: Core.shared.transactionAdapterManager,
            rateService: rateService,
            nftMetadataService: nftMetadataService,
            balanceHiddenManager: Core.shared.balanceHiddenManager
        )

        let contactLabelService = TransactionsContactLabelService(contactManager: Core.shared.contactManager)
        let viewItemFactory = TransactionsViewItemFactory(evmLabelManager: Core.shared.evmLabelManager, contactLabelService: contactLabelService)
        let viewModel = TransactionsViewModel(service: service, contactLabelService: contactLabelService, factory: viewItemFactory)
        let dataSource = TransactionsTableViewDataSource(viewModel: viewModel, statPage: .transactions)

        return TransactionsViewController(viewModel: viewModel, dataSource: dataSource)
    }

    static func dataSource(token: Token, statPage: StatPage) -> TransactionsTableViewDataSource {
        let rateService = HistoricalRateService(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager)
        let nftMetadataService = NftMetadataService(nftMetadataManager: Core.shared.nftMetadataManager)

        let service = TokenTransactionsService(
            token: token,
            adapterManager: Core.shared.transactionAdapterManager,
            rateService: rateService,
            nftMetadataService: nftMetadataService
        )

        let contactLabelService = TransactionsContactLabelService(contactManager: Core.shared.contactManager)
        let viewItemFactory = TransactionsViewItemFactory(evmLabelManager: Core.shared.evmLabelManager, contactLabelService: contactLabelService)
        let viewModel = BaseTransactionsViewModel(service: service, contactLabelService: contactLabelService, factory: viewItemFactory)

        return TransactionsTableViewDataSource(viewModel: viewModel, statPage: statPage)
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
    var contact: Contact?
    var scamFilterEnabled: Bool

    init() {
        blockchain = nil
        token = nil
        contact = nil
        scamFilterEnabled = true
    }

    init(token: Token) {
        blockchain = token.blockchain
        self.token = token
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

        // reset contact if selected blockchain not allowed for search by contact
        guard TransactionContactSelectViewModel.allowedBlockchainUids.contains(blockchain.type.uid) else {
            self.contact = nil
            return
        }

        // reset contact if it's doesnt have address for selected blockchain
        guard contact.has(blockchainUId: blockchain.uid) else {
            self.contact = nil
            return
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

    mutating func reset() {
        blockchain = nil
        token = nil
        contact = nil
        scamFilterEnabled = true
    }
}
