import RxSwift
import RxRelay
import StorageKit

class BalanceHiddenManager {
    private let keyBalanceHidden = "wallet-balance-hidden"
    private let keyBalanceAutoHide = "wallet-balance-auto-hide"

    private let localStorage: StorageKit.ILocalStorage

    private let balanceHiddenRelay = PublishRelay<Bool>()
    private(set) var balanceHidden: Bool {
        didSet {
            balanceHiddenRelay.accept(balanceHidden)
        }
    }

    private(set) var balanceAutoHide: Bool

    init(localStorage: StorageKit.ILocalStorage) {
        self.localStorage = localStorage

        if let balanceHidden: Bool = localStorage.value(for: keyBalanceHidden) {
            self.balanceHidden = balanceHidden
        } else if let balanceHidden: Bool = localStorage.value(for: "balance_hidden") {
            // todo: temp solution for restoring from version 0.22
            self.balanceHidden = balanceHidden
        } else {
            balanceHidden = false
        }

        balanceAutoHide = localStorage.value(for: keyBalanceAutoHide) ?? false

        if balanceAutoHide {
            set(balanceHidden: true)
        }
    }

    private func set(balanceHidden: Bool) {
        self.balanceHidden = balanceHidden
        localStorage.set(value: balanceHidden, for: keyBalanceHidden)
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
        localStorage.set(value: balanceAutoHide, for: keyBalanceAutoHide)

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
