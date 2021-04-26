import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import CoinKit

class MarketTickerService {
    private let disposeBag = DisposeBag()

    private let marketTickerRelay = BehaviorRelay<DataStatus<[Item]>>(value: .loading)
    private var marketTicker: DataStatus<[Item]> = .loading

    private let currencyKit: CurrencyKit.Kit

    init(currencyKit: CurrencyKit.Kit) {
        self.currencyKit = currencyKit

        fetchTickerData()
    }

    private func fetchTickerData() {
//        let tickerData = [
//            Item(
//                coin: App.shared.appConfigProvider.featuredCoins[0],
//                currencyValue: CurrencyValue(currency: currencyKit.baseCurrency, value: 1234),
//                timeInterval: 40 * 60, fee: 75),
//            Item(
//                coin: App.shared.appConfigProvider.featuredCoins[1],
//                currencyValue: CurrencyValue(currency: currencyKit.baseCurrency, value: 354),
//                timeInterval: 40 * 60, fee: 25),
//        ]

        marketTickerRelay.accept(.completed([]))
    }

}

extension MarketTickerService {

    public var marketTickerDataObservable: Observable<DataStatus<[Item]>> {
        marketTickerRelay.asObservable()
    }

    public func refresh() {
        fetchTickerData()
    }

}

extension MarketTickerService {

    struct Item {
        let coin: Coin
        let currencyValue: CurrencyValue
        let timeInterval: TimeInterval
        let fee: Decimal
    }

}
