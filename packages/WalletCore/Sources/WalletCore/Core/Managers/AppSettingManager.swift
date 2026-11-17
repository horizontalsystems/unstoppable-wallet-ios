import Combine
import RxRelay
import RxSwift

class AppSettingManager {
    static let defaultBalancePrimaryValue: BalancePrimaryValue = .coin

    private static let keyBalancePrimaryValue = "balance-primary-value"

    private let userDefaultsStorage: UserDefaultsStorage

    private let balancePrimaryValueRelay = PublishRelay<BalancePrimaryValue>()
    var balancePrimaryValue: BalancePrimaryValue {
        didSet {
            balancePrimaryValueRelay.accept(balancePrimaryValue)
            userDefaultsStorage.set(value: balancePrimaryValue.rawValue, for: Self.keyBalancePrimaryValue)
        }
    }

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        if let rawValue: String = userDefaultsStorage.value(for: Self.keyBalancePrimaryValue), let value = BalancePrimaryValue(rawValue: rawValue) {
            balancePrimaryValue = value
        } else {
            balancePrimaryValue = Self.defaultBalancePrimaryValue
        }
    }
}

extension AppSettingManager {
    var balancePrimaryValueObservable: Observable<BalancePrimaryValue> {
        balancePrimaryValueRelay.asObservable()
    }
}
