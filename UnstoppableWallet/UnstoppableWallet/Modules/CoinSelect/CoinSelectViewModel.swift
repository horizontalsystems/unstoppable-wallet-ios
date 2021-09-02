import Foundation
import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit

class CoinSelectViewModel {
    private let service: CoinSelectService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private var filter: String?

    init(service: CoinSelectService) {
        self.service = service

        sync()
    }

    private func sync() {
        let viewItems = filteredItems.map { item -> ViewItem in
            let formatted = item.balance
                    .flatMap { CoinValueNew(kind: .platformCoin(platformCoin: item.platformCoin), value: $0) }
                    .flatMap { ValueFormatter.instance.format(coinValueNew: $0, fractionPolicy: .threshold(high: 0.01, low: 0)) }

            let fiatFormatted = item.rate
                    .flatMap { rate in item.balance.map { $0 * rate } }
                    .flatMap { CurrencyValue(currency: service.currency, value: $0) }
                    .flatMap { ValueFormatter.instance.format(currencyValue: $0) }

            return ViewItem(platformCoin: item.platformCoin, balance: formatted, fiatBalance: fiatFormatted)
        }

        viewItemsRelay.accept(viewItems)
    }

    private var filteredItems: [CoinSelectService.Item] {
        guard let filter = filter else {
            return service.items
        }

        return service.items.filter { item in
            item.platformCoin.coin.name.localizedCaseInsensitiveContains(filter)  || item.platformCoin.coin.code.localizedCaseInsensitiveContains(filter)
        }
    }

}

extension CoinSelectViewModel {

    public var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    func apply(filter: String?) {
        self.filter = filter

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.sync()
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
