import Foundation
import RxSwift
import RxCocoa

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
                    .flatMap { CoinValue(coin: item.coin, value: $0) }
                    .flatMap { ValueFormatter.instance.format(coinValue: $0, fractionPolicy: .threshold(high: 0.01, low: 0)) }

            return ViewItem(coin: item.coin, balance: formatted, fiatBalance: nil, blockchainType: item.blockchainType)
        }

        viewItemsRelay.accept(viewItems)
    }

    private var filteredItems: [CoinSelectService.Item] {
        guard let filter = filter else {
            return service.items
        }

        return service.items.filter { item in
            item.coin.title.localizedCaseInsensitiveContains(filter)  || item.coin.code.localizedCaseInsensitiveContains(filter)
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
        let coin: Coin
        let balance: String?
        let fiatBalance: String?
        let blockchainType: String?
    }

}
