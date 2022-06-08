import Foundation
import RxSwift
import RxCocoa
import RxRelay
import MarketKit

class SendBitcoinAmountInputService {
    weak var availableBalanceService: IAvailableBalanceService?

    let token: Token?

    private var amountRelay = BehaviorRelay<Decimal>(value: 0)
    var amount: Decimal = 0 {
        didSet {
            if amount != oldValue {
                amountRelay.accept(amount)
            }
        }
    }

    init(token: Token) {
        self.token = token
    }

}

extension SendBitcoinAmountInputService: IAmountInputService {

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

    var tokenObservable: Observable<Token?> {
        Observable.just(token)
    }

    func onChange(amount: Decimal) {
        self.amount = amount
    }

}
