import RxRelay
import RxSwift

class BalancePrimaryValueManager {
    private let keyBalancePrimaryValue = "balance-primary-value"

    private let userDefaultsStorage: UserDefaultsStorage

    private let balancePrimaryValueRelay = PublishRelay<BalancePrimaryValue>()
    var balancePrimaryValue: BalancePrimaryValue {
        didSet {
            balancePrimaryValueRelay.accept(balancePrimaryValue)
            userDefaultsStorage.set(value: balancePrimaryValue.rawValue, for: keyBalancePrimaryValue)
        }
    }

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        if let rawValue: String = userDefaultsStorage.value(for: keyBalancePrimaryValue), let value = BalancePrimaryValue(rawValue: rawValue) {
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
