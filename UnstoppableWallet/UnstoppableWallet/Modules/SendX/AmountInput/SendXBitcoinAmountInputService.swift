import Foundation
import RxSwift
import RxCocoa
import RxRelay
import MarketKit

class SendXBitcoinAmountInputService {
    weak var availableBalanceService: IAvailableBalanceService?

    let platformCoin: PlatformCoin?

    private var amountRelay = BehaviorRelay<Decimal>(value: 0)
    var amount: Decimal = 0 {
        didSet {
            if amount != oldValue {
                amountRelay.accept(amount)
            }
        }
    }

    init(platformCoin: PlatformCoin) {
        self.platformCoin = platformCoin
    }

}

extension SendXBitcoinAmountInputService: IAmountInputService {

    var amountObservable: Observable<Decimal> {
        amountRelay.asObservable()
    }

    var balance: Decimal? {
        availableBalanceService?.availableBalance.data
    }

    var balanceObservable: Observable<Decimal?> {
        guard let availableBalanceService = availableBalanceService else {
            return .just(nil)
        }

        return availableBalanceService.availableBalanceObservable.map {
            $0.data
        }
    }

    var platformCoinObservable: Observable<PlatformCoin?> {
        Observable.just(platformCoin)
    }

    func onChange(amount: Decimal) {
        self.amount = amount
    }

}
