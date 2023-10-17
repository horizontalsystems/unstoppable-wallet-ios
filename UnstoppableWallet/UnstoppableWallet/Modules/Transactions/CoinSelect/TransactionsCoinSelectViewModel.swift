import Foundation
import RxSwift
import RxCocoa
import MarketKit

class TransactionsCoinSelectViewModel {
    private let service: TransactionsCoinSelectService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    init(service: TransactionsCoinSelectService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [TransactionsCoinSelectService.Item]) {
        let viewItems = items.map { item -> ViewItem in
            switch item.type {
            case .all:
                return ViewItem(type: .all, selected: item.selected)
            case .token(let token):
                let tokenViewItem = TokenViewItem(
                        imageUrl: token.coin.imageUrl,
                        placeholderImageName: token.placeholderImageName,
                        name: token.coin.name,
                        code: token.coin.code,
                        badge: token.badge
                )

                return ViewItem(type: .token(viewItem: tokenViewItem), selected: item.selected)
            }
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension TransactionsCoinSelectViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    func apply(filter: String?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.service.set(filter: filter?.trimmingCharacters(in: .whitespaces) ?? "")
        }
    }

    func onSelect(index: Int) {
        service.handleSelected(index: index)
    }

}

extension TransactionsCoinSelectViewModel {

    struct ViewItem {
        let type: ViewItemType
        let selected: Bool
    }

    enum ViewItemType {
        case all
        case token(viewItem: TokenViewItem)
    }

    struct TokenViewItem {
        let imageUrl: String
        let placeholderImageName: String
        let name: String
        let code: String
        let badge: String?
    }

}
