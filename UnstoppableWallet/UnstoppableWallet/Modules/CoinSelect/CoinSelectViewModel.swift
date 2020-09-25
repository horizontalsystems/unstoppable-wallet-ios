import Foundation
import RxSwift
import RxCocoa

class CoinSelectViewModel {
    private let disposeBag = DisposeBag()

    private var coinViewItemsRelay = BehaviorRelay<[CoinBalanceViewItem]>(value: [])
    private let coins: [SwapModule.CoinBalanceItem]

    private var filter: String?

    init(coins: [SwapModule.CoinBalanceItem]) {
        self.coins = coins

        sync()
    }

    private var filtered :[SwapModule.CoinBalanceItem] {
        guard let filter = filter else {
            return coins
        }

        return coins.filter { item in
            item.coin.title.localizedCaseInsensitiveContains(filter)  || item.coin.code.localizedCaseInsensitiveContains(filter)
        }
    }

    private func sync() {
        let viewItems = filtered.map { item -> CoinBalanceViewItem in
            let formatted = item.balance
                    .flatMap { CoinValue(coin: item.coin, value: $0) }
                    .flatMap { ValueFormatter.instance.format(coinValue: $0, fractionPolicy: .threshold(high: 0.01, low: 0)) }

            return CoinBalanceViewItem(coin: item.coin, balance: formatted, blockchainType: item.blockchainType)
        }
        coinViewItemsRelay.accept(viewItems)
    }

}

extension CoinSelectViewModel {

    public var coinViewItems: Driver<[CoinBalanceViewItem]> {
        coinViewItemsRelay.asDriver()
    }

    public func coin(at index: Int) -> SwapModule.CoinBalanceItem? {
        let coins = filtered

        guard index < coins.count else {
            return nil
        }
        return coins[index]
    }

    func onUpdate(filter: String?) {
        self.filter = filter

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.sync()
        }
    }

}
