import CurrencyKit
import RxSwift
import RxRelay

enum AmountType {
    case coin
    case currency
}

class FiatService {
    private var disposeBag = DisposeBag()
    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager

    var coin: Coin? {
        didSet {
            sync()
        }
    }

    var amount: Decimal? {
        didSet {
            sync()
        }
    }

    var amountType: AmountType = .coin {
        didSet {
            sync()
        }
    }

    private let coinValueRelay = PublishRelay<CoinValue?>()
    private(set) var coinValue: CoinValue? {
        didSet {
            coinValueRelay.accept(coinValue)
        }
    }

    private let currencyValueRelay = PublishRelay<CurrencyValue?>()
    private(set) var currencyValue: CurrencyValue? {
        didSet {
            currencyValueRelay.accept(currencyValue)
        }
    }

    init(currencyKit: ICurrencyKit, rateManager: IRateManager) {
        self.currencyKit = currencyKit
        self.rateManager = rateManager
    }

    private func update<T: Equatable>(old: inout T, new: T) {
        if old != new {
            old = new
        }
    }

    private func rate(coin: Coin, currency: Currency) -> Decimal? {
        rateManager.marketInfo(coinCode: coin.code, currencyCode: currency.code).map { $0.rate }
    }

    private func sync() {
        let baseCurrency = currencyKit.baseCurrency

        guard let coin = coin, //Not enough data. Set all relay to nil, if needed
              let amount = amount else {

            update(old: &self.coinValue, new: nil)
            update(old: &self.currencyValue, new: nil)

            return
        }

        switch amountType {
        case .coin:
            update(old: &self.coinValue, new: CoinValue(coin: coin, value: amount))

            let currencyValue = rate(coin: coin, currency: baseCurrency).map {
                CurrencyValue(currency: baseCurrency, value: $0 * amount)
            }

            update(old: &self.currencyValue, new: currencyValue)
        case .currency:
            update(old: &self.currencyValue, new: CurrencyValue(currency: baseCurrency, value: amount))

            let coinValue = rate(coin: coin, currency: baseCurrency).map {
                CoinValue(coin: coin, value: $0 == 0 ? 0 : amount / $0)
            }

            update(old: &self.coinValue, new: coinValue)
        }
    }

}

extension FiatService {

    var coinValueObservable: Observable<CoinValue?> {
        coinValueRelay.asObservable()
    }

    var currencyValueObservable: Observable<CurrencyValue?> {
        currencyValueRelay.asObservable()
    }

}
