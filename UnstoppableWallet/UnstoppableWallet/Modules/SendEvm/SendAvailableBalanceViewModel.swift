import RxSwift
import RxCocoa
import BigInt

protocol IAvailableBalanceService {
    var availableBalance: Decimal { get }
}

class SendAvailableBalanceViewModel {
    private let service: IAvailableBalanceService
    private let coinService: CoinService
    private let disposeBag = DisposeBag()

    private let viewStateRelay = BehaviorRelay<ViewState>(value: .loading)

    init(service: IAvailableBalanceService, coinService: CoinService) {
        self.service = service
        self.coinService = coinService

        sync()
    }

    private func sync() {
        let coinValue = CoinValue(coin: coinService.coin, value: service.availableBalance)
        let value = ValueFormatter.instance.format(coinValue: coinValue)

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
