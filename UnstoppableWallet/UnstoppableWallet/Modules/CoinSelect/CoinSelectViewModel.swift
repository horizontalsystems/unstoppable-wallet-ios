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
                    .flatMap { CoinValue(kind: .platformCoin(platformCoin: item.platformCoin), value: $0) }
                    .flatMap { ValueFormatter.instance.format(coinValue: $0, fractionPolicy: .threshold(high: 0.01, low: 0)) }

            let fiatFormatted = item.rate
                    .flatMap { rate in item.balance.map { $0 * rate } }
                    .flatMap { CurrencyValue(currency: service.currency, value: $0) }
                    .flatMap { ValueFormatter.instance.format(currencyValue: $0) }

            return ViewItem(platformCoin: item.platformCoin, balance: formatted, fiatBalance: fiatFormatted)
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
        let platformCoin: PlatformCoin
        let balance: String?
        let fiatBalance: String?
    }

}
