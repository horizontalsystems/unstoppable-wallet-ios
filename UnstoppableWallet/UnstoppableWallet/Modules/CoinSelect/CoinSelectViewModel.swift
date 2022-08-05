import Foundation
import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit

class CoinSelectViewModel {
    private let service: CoinSelectService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    init(service: CoinSelectService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [CoinSelectService.Item]) {
        let viewItems = items.map { item -> ViewItem in
            let formatted = item.balance
                    .flatMap { CoinValue(kind: .token(token: item.token), value: $0) }
                    .flatMap { ValueFormatter.instance.formatShort(coinValue: $0) }

            let fiatFormatted = item.rate
                    .flatMap { rate in item.balance.map { $0 * rate } }
                    .flatMap { ValueFormatter.instance.formatShort(currency: service.currency, value: $0) }

            return ViewItem(token: item.token, balance: formatted, fiatBalance: fiatFormatted)
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension CoinSelectViewModel {

    public var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    func apply(filter: String?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.service.set(filter: filter?.trimmingCharacters(in: .whitespaces) ?? "")
        }
    }

}

extension CoinSelectViewModel {

    struct ViewItem {
        let token: Token
        let balance: String?
        let fiatBalance: String?
    }

}
