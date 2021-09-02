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
        let coinValue = CoinValueNew(kind: .platformCoin(platformCoin: coinService.platformCoin), value: service.availableBalance)
        let value = ValueFormatter.instance.format(coinValueNew: coinValue)

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
