import RxRelay
import RxSwift

class AppSettingManager {
    private let keyBalancePrimaryValue = "balance-primary-value"
    private let keyRecipientAddressCheck = "recipient-address-check"

    private let userDefaultsStorage: UserDefaultsStorage

    private let balancePrimaryValueRelay = PublishRelay<BalancePrimaryValue>()
    var balancePrimaryValue: BalancePrimaryValue {
        didSet {
            balancePrimaryValueRelay.accept(balancePrimaryValue)
            userDefaultsStorage.set(value: balancePrimaryValue.rawValue, for: keyBalancePrimaryValue)
        }
    }

    var recipientAddressCheck: Bool {
        didSet {
            userDefaultsStorage.set(value: recipientAddressCheck, for: keyRecipientAddressCheck)
        }
    }

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        if let rawValue: String = userDefaultsStorage.value(for: keyBalancePrimaryValue), let value = BalancePrimaryValue(rawValue: rawValue) {
            balancePrimaryValue = value
        } else {
            balancePrimaryValue = .coin
        }

        recipientAddressCheck = userDefaultsStorage.value(for: keyRecipientAddressCheck) ?? true
    }
}

extension AppSettingManager {
    var balancePrimaryValueObservable: Observable<BalancePrimaryValue> {
        balancePrimaryValueRelay.asObservable()
    }
}
