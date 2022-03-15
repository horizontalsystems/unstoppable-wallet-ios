import RxSwift
import RxCocoa
import BigInt
import CurrencyKit

protocol IAvailableBalanceService: AnyObject {
    var availableBalance: DataStatus<Decimal> { get }
    var availableBalanceObservable: Observable<DataStatus<Decimal>> { get }
}

class SendAvailableBalanceViewModel {
    private let service: IAvailableBalanceService
    private let coinService: CoinService
    private let switchService: AmountTypeSwitchService
    private let disposeBag = DisposeBag()

    private let viewStateRelay = BehaviorRelay<ViewState>(value: .loading)

    init(service: IAvailableBalanceService, coinService: CoinService, switchService: AmountTypeSwitchService) {
        self.service = service
        self.coinService = coinService
        self.switchService = switchService

        subscribe(disposeBag, switchService.amountTypeObservable) { [weak self] _ in self?.sync() }
        subscribe(disposeBag, service.availableBalanceObservable) { [weak self] _ in self?.sync() }

        sync()
    }

    private var hasPreviousValue: Bool {
        if case .loaded = viewStateRelay.value {
            return true
        }
        return false
    }

    private func sync() {
        switch service.availableBalance {
        case .loading:
            if !hasPreviousValue {
                viewStateRelay.accept(.loading)
            }
        case .failed: updateViewState(availableBalance: 0)
        case .completed(let availableBalance): updateViewState(availableBalance: availableBalance)
        }
    }

    private func updateViewState(availableBalance: Decimal) {
        let value: String?

        if case .currency = switchService.amountType, let rate = coinService.rate {
            let currencyValue = CurrencyValue(currency: rate.currency, value: availableBalance * rate.value)
            value = ValueFormatter.instance.format(currencyValue: currencyValue)
        } else {
            let coinValue = CoinValue(kind: .platformCoin(platformCoin: coinService.platformCoin), value: availableBalance)
            value = ValueFormatter.instance.format(coinValue: coinValue)!
        }

        viewStateRelay.accept(.loaded(value: value))
    }

}

extension SendAvailableBalanceViewModel {

    var viewStateDriver: Driver<ViewState> {
        viewStateRelay.asDriver()
    }

}

extension SendAvailableBalanceViewModel {

    enum ViewState {
        case loading
        case loaded(value: String?)
    }

}
