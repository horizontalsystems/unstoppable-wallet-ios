import Foundation
import RxSwift
import RxCocoa
import BigInt
import CurrencyKit

protocol IAvailableBalanceService: AnyObject {
    var availableBalance: DataStatus<Decimal> { get }
    var availableBalanceObservable: Observable<DataStatus<Decimal>> { get }
}

protocol ISendAvailableBalanceViewModel: AnyObject {
    var viewStateDriver: Driver<SendAvailableBalanceViewModel.ViewState> { get }
}

class SendAvailableBalanceViewModel {
    private var queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.available-balance-view-model", qos: .userInitiated)

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
        queue.async { [weak self] in
            guard let weakSelf = self else {
                return
            }

            switch weakSelf.service.availableBalance {
            case .loading:
                if !weakSelf.hasPreviousValue {
                    weakSelf.viewStateRelay.accept(.loading)
                }
            case .failed: weakSelf.updateViewState(availableBalance: 0)
            case .completed(let availableBalance): weakSelf.updateViewState(availableBalance: availableBalance)
            }
        }
    }

    private func updateViewState(availableBalance: Decimal) {
        let value: String?

        if case .currency = switchService.amountType, let rate = coinService.rate {
            let currencyValue = CurrencyValue(currency: rate.currency, value: availableBalance * rate.value)
            value = ValueFormatter.instance.formatFull(currencyValue: currencyValue)
        } else {
            let coinValue = CoinValue(kind: .token(token: coinService.token), value: availableBalance)
            value = ValueFormatter.instance.formatFull(coinValue: coinValue)
        }

        viewStateRelay.accept(.loaded(value: value))
    }

}

extension SendAvailableBalanceViewModel: ISendAvailableBalanceViewModel {

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
