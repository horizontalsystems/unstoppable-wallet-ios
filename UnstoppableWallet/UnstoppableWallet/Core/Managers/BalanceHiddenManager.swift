import RxSwift
import RxRelay
import StorageKit

class BalanceHiddenManager {
    private let keyBalanceHidden = "wallet-balance-hidden"

    private let localStorage: StorageKit.ILocalStorage

    private let balanceHiddenRelay = PublishRelay<Bool>()
    private(set) var balanceHidden: Bool {
        didSet {
            balanceHiddenRelay.accept(balanceHidden)
        }
    }

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
    }

}

extension BalanceHiddenManager {

    var balanceHiddenObservable: Observable<Bool> {
        balanceHiddenRelay.asObservable()
    }

    func toggleBalanceHidden() {
        balanceHidden = !balanceHidden
        localStorage.set(value: balanceHidden, for: keyBalanceHidden)
    }

}
