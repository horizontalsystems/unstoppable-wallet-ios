import Foundation
import RxSwift
import RxCocoa
import MarketKit
import ComponentKit

class TransactionsViewModel: BaseTransactionsViewModel {
    private let service: TransactionsService
    private let disposeBag = DisposeBag()

    private let blockchainTitleRelay = BehaviorRelay<String?>(value: nil)
    private let tokenTitleRelay = BehaviorRelay<String?>(value: nil)

    init(service: TransactionsService, contactLabelService: TransactionsContactLabelService, factory: TransactionsViewItemFactory) {
        self.service = service

        super.init(service: service, contactLabelService: contactLabelService, factory: factory)

        subscribe(disposeBag, service.blockchainObservable) { [weak self] in self?.syncBlockchainTitle(blockchain: $0) }
        subscribe(disposeBag, service.tokenObservable) { [weak self] in self?.syncTokenTitle(token: $0) }

        syncBlockchainTitle(blockchain: service.blockchain)
        syncTokenTitle(token: service.token)
    }

    private func syncBlockchainTitle(blockchain: Blockchain?) {
        let title: String

        if let blockchain = blockchain {
            title = blockchain.name
        } else {
            title = "transactions.all_blockchains".localized
        }

        blockchainTitleRelay.accept(title)
    }

    private func syncTokenTitle(token: Token?) {
        var title: String

        if let token {
            title = token.coin.code

            if let badge = token.badge {
                title += " (\(badge))"
            }
        } else {
            title = "transactions.all_coins".localized
        }

        tokenTitleRelay.accept(title)
    }

}

extension TransactionsViewModel {

    var blockchainTitleDriver: Driver<String?> {
        blockchainTitleRelay.asDriver()
    }

    var tokenTitleDriver: Driver<String?> {
        tokenTitleRelay.asDriver()
    }

    var blockchainViewItems: [BlockchainViewItem] {
        [BlockchainViewItem(uid: nil, title: "transactions.all_blockchains".localized, selected: service.blockchain == nil)] +
                service.allBlockchains.sorted { $0.type.order < $1.type.order }.map { blockchain in
                    BlockchainViewItem(uid: blockchain.uid, title: blockchain.name, selected: service.blockchain == blockchain)
                }
    }

    var token: Token? {
        service.token
    }

    func onSelectBlockchain(uid: String?) {
        service.set(blockchain: service.allBlockchains.first(where: { $0.uid == uid }))
    }

    func onSelect(token: Token?) {
        service.set(token: token)
    }

}
