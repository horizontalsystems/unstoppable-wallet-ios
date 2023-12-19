import RxRelay
import RxSwift

class BalanceHiddenManager {
    static let placeholder = "*****"
    private let keyBalanceHidden = "wallet-balance-hidden"
    private let keyBalanceAutoHide = "wallet-balance-auto-hide"

    private let userDefaultsStorage: UserDefaultsStorage

    private let balanceHiddenRelay = PublishRelay<Bool>()
    private(set) var balanceHidden: Bool {
        didSet {
            balanceHiddenRelay.accept(balanceHidden)
        }
    }

    private(set) var balanceAutoHide: Bool

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        if let balanceHidden: Bool = userDefaultsStorage.value(for: keyBalanceHidden) {
            self.balanceHidden = balanceHidden
        } else if let balanceHidden: Bool = userDefaultsStorage.value(for: "balance_hidden") {
            // TODO: temp solution for restoring from version 0.22
            self.balanceHidden = balanceHidden
        } else {
            balanceHidden = false
        }

        balanceAutoHide = userDefaultsStorage.value(for: keyBalanceAutoHide) ?? false

        if balanceAutoHide {
            set(balanceHidden: true)
        }
    }

    private func set(balanceHidden: Bool) {
        self.balanceHidden = balanceHidden
        userDefaultsStorage.set(value: balanceHidden, for: keyBalanceHidden)
    }
}

extension BalanceHiddenManager {
    var balanceHiddenObservable: Observable<Bool> {
        balanceHiddenRelay.asObservable()
    }

    func toggleBalanceHidden() {
        set(balanceHidden: !balanceHidden)
    }

    func set(balanceAutoHide: Bool) {
        self.balanceAutoHide = balanceAutoHide
        userDefaultsStorage.set(value: balanceAutoHide, for: keyBalanceAutoHide)

        if balanceAutoHide {
            set(balanceHidden: true)
        }
    }

    func didEnterBackground() {
        if balanceAutoHide {
            set(balanceHidden: true)
        }
    }
}
