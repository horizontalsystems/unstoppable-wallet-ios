import RxSwift
import RxRelay
import XRatesKit
import CurrencyKit
import CoinKit

protocol IWalletRateServiceDelegate: AnyObject {
    func didUpdateBaseCurrency()
    func didUpdate(itemsMap: [CoinType: WalletRateService.Item])
}

class WalletRateService {
    weak var delegate: IWalletRateServiceDelegate?

    private let currencyKit: CurrencyKit.Kit
    private let rateManager: IRateManager
    private let scheduler: ImmediateSchedulerType
    private let disposeBag = DisposeBag()
    private var latestRatesDisposeBag = DisposeBag()

    private var coinTypes = [CoinType]()

    init(currencyKit: CurrencyKit.Kit, rateManager: IRateManager, scheduler: ImmediateSchedulerType) {
        self.currencyKit = currencyKit
        self.rateManager = rateManager
        self.scheduler = scheduler

        subscribe(scheduler, disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] baseCurrency in
            self?.onUpdate(baseCurrency: baseCurrency)
        }
    }

    private func onUpdate(baseCurrency: Currency) {
        subscribeToLatestRates()
        delegate?.didUpdateBaseCurrency()
    }

    private func subscribeToLatestRates() {
        latestRatesDisposeBag = DisposeBag()

        subscribe(scheduler, latestRatesDisposeBag, rateManager.latestRatesObservable(coinTypes: coinTypes, currencyCode: currencyKit.baseCurrency.code)) { [weak self] in
            self?.onUpdate(latestRates: $0)
        }
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

    var currency: Currency {
        currencyKit.baseCurrency
    }

    func set(coinTypes: [CoinType]) {
        self.coinTypes = coinTypes
        subscribeToLatestRates()
    }

    func item(coinType: CoinType) -> Item? {
        guard let latestRate = rateManager.latestRate(coinType: coinType, currencyCode: currency.code) else {
            return nil
        }

        return item(latestRate: latestRate)
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
