import Foundation
import RxSwift
import RxCocoa

class CoinSelectViewModel {
    private let disposeBag = DisposeBag()

    private var coinViewItemsRelay = BehaviorRelay<[CoinBalanceViewItem]>(value: [])
    private let coins: [SwapModule.CoinBalanceItem]

    init(coins: [SwapModule.CoinBalanceItem]) {
        self.coins = coins

        sync()
    }

    private func sync() {
        let viewItems = coins.map { item -> CoinBalanceViewItem in
            let formatted = item.balance
                    .flatMap { CoinValue(coin: item.coin, value: $0) }
                    .flatMap { ValueFormatter.instance.format(coinValue: $0, fractionPolicy: .threshold(high: 0.01, low: 0)) }

            return CoinBalanceViewItem(coin: item.coin, balance: formatted)
        }
        coinViewItemsRelay.accept(viewItems)
    }

}

extension CoinSelectViewModel {

    public var coinViewItems: Driver<[CoinBalanceViewItem]> {
        coinViewItemsRelay.asDriver()
    }

    public func coin(at index: Int) -> SwapModule.CoinBalanceItem? {
        guard index < coins.count else {
            return nil
        }
        return coins[index]
    }

}
