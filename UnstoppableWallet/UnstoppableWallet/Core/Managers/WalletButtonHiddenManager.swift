import RxRelay
import RxSwift

class WalletButtonHiddenManager {
    private let keyButtonHidden = "wallet-button-hidden"

    private let userDefaultsStorage: UserDefaultsStorage

    private let buttonHiddenRelay = PublishRelay<Bool>()
    var buttonHidden: Bool {
        get {
            userDefaultsStorage.value(for: keyButtonHidden) ?? false
        }
        set {
            guard buttonHidden != newValue else { return }
            userDefaultsStorage.set(value: newValue, for: keyButtonHidden)
            buttonHiddenRelay.accept(newValue)
        }
    }

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage
    }
}

extension WalletButtonHiddenManager {
    var buttonHiddenObservable: Observable<Bool> {
        buttonHiddenRelay.asObservable()
    }
}
