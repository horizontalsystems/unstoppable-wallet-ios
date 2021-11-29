import RxSwift
import RxCocoa
import BigInt
import CurrencyKit

protocol IAvailableBalanceService {
    var availableBalance: Decimal { get }
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

        subscribe(disposeBag, switchService.amountTypeObservable) { [weak self] in self?.sync(amountType: $0) }

        sync(amountType: switchService.amountType)
    }

    private func sync(amountType: AmountTypeSwitchService.AmountType) {
        let value: String?

        if case .currency = amountType, let rate = coinService.rate {
            let currencyValue = CurrencyValue(currency: rate.currency, value: service.availableBalance * rate.value)
            value = ValueFormatter.instance.format(currencyValue: currencyValue)
        } else {
            let coinValue = CoinValue(kind: .platformCoin(platformCoin: coinService.platformCoin), value: service.availableBalance)
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
