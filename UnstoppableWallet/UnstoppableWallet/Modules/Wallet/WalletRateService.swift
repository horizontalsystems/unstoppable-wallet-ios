import RxSwift
import RxRelay
import XRatesKit
import CurrencyKit
import MarketKit

protocol IWalletRateServiceDelegate: AnyObject {
    func didUpdateBaseCurrency()
    func didUpdate(itemsMap: [CoinType: WalletRateService.Item])
}

class WalletRateService {
    weak var delegate: IWalletRateServiceDelegate?

    private let currencyKit: CurrencyKit.Kit
    private let rateManager: IRateManager
    private let disposeBag = DisposeBag()
    private var latestRatesDisposeBag = DisposeBag()

    private(set) var currency: Currency
    private var coinTypes = [CoinType]()

    init(currencyKit: CurrencyKit.Kit, rateManager: IRateManager) {
        self.currencyKit = currencyKit
        self.rateManager = rateManager

        currency = currencyKit.baseCurrency

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] baseCurrency in
            self?.onUpdate(baseCurrency: baseCurrency)
        }
    }

    private func onUpdate(baseCurrency: Currency) {
        currency = baseCurrency
        subscribeToLatestRates()
        delegate?.didUpdateBaseCurrency()
    }

    private func subscribeToLatestRates() {
        latestRatesDisposeBag = DisposeBag()

//        subscribe(latestRatesDisposeBag, rateManager.latestRatesObservable(coinTypes: coinTypes, currencyCode: currencyKit.baseCurrency.code)) { [weak self] in
//            self?.onUpdate(latestRates: $0)
//        }
    }

    private func onUpdate(latestRates: [CoinType: LatestRate]) {
        let itemsMap = latestRates.mapValues { item(latestRate: $0) }
        delegate?.didUpdate(itemsMap: itemsMap)
    }

    private func item(latestRate: LatestRate) -> Item {
        let currency = currencyKit.baseCurrency

        return Item(
                rate: CurrencyValue(currency: currency, value: latestRate.rate),
                diff24h: latestRate.rateDiff24h,
                expired: latestRate.expired
        )
    }

}

extension WalletRateService {

    func set(coinTypes: [CoinType]) {
        self.coinTypes = coinTypes
        subscribeToLatestRates()
    }

    func itemMap(coinTypes: [CoinType]) -> [CoinType: Item] {
//        rateManager.latestRateMap(coinTypes: coinTypes, currencyCode: currency.code).mapValues { item(latestRate: $0) }
        [:]
    }

    func refresh() {
        rateManager.refresh(currencyCode: currency.code)
    }

}

extension WalletRateService {

    struct Item {
        let rate: CurrencyValue
        let diff24h: Decimal
        let expired: Bool
    }

}
