import Erc20Kit
import RxSwift
import RxCocoa

class Erc20AvailableBalanceViewModel {
    private let service: Erc20AvailableBalanceService
    private let coinService: CoinService

    private let disposeBag = DisposeBag()

    private let balanceRelay = BehaviorRelay<String>(value: "n/a".localized)

    init(service: Erc20AvailableBalanceService, coinService: CoinService) {
        self.service = service
        self.coinService = coinService

        if let balance = service.erc20Balance {
            balanceRelay.accept(coinService.coinValue(value: balance).formattedString)
        } else {
            balanceRelay.accept("n/a".localized)
        }
    }

}

extension Erc20AvailableBalanceViewModel: IAvailableBalanceCellViewModel {

    var balanceDriver: Driver<String> {
        balanceRelay.asDriver()
    }

}
