import RxSwift
import RxRelay
import StorageKit

class BalancePrimaryValueManager {
    private let keyBalancePrimaryValue = "balance-primary-value"

    private let localStorage: StorageKit.ILocalStorage

    private let balancePrimaryValueRelay = PublishRelay<BalancePrimaryValue>()
    var balancePrimaryValue: BalancePrimaryValue {
        didSet {
            balancePrimaryValueRelay.accept(balancePrimaryValue)
            localStorage.set(value: balancePrimaryValue.rawValue, for: keyBalancePrimaryValue)
        }
    }

    init(localStorage: StorageKit.ILocalStorage) {
        self.localStorage = localStorage

        if let rawValue: String = localStorage.value(for: keyBalancePrimaryValue), let value = BalancePrimaryValue(rawValue: rawValue) {
            balancePrimaryValue = value
        } else {
            balancePrimaryValue = .coin
        }
    }

}

extension BalancePrimaryValueManager {

    var balancePrimaryValueObservable: Observable<BalancePrimaryValue> {
        balancePrimaryValueRelay.asObservable()
    }

}
