import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

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

    init(token: Token, amount: Decimal = 0) {
        self.token = token
        self.amount = amount
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
        guard let availableBalanceService else {
            return .just(nil)
        }

        return availableBalanceService.availableBalanceObservable.map(\.data)
    }

    var tokenObservable: Observable<Token?> {
        Observable.just(token)
    }

    func onChange(amount: Decimal) {
        self.amount = amount
    }
}
