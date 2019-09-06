import RxSwift

class PinManager {
    private let secureStorage: ISecureStorage
    private let localStorage: ILocalStorage

    private let isPinSetSubject = PublishSubject<Bool>()

    init(secureStorage: ISecureStorage, localStorage: ILocalStorage) {
        self.secureStorage = secureStorage
        self.localStorage = localStorage
    }

}

extension PinManager: IPinManager {

    var isPinSet: Bool {
        return secureStorage.pin != nil
    }

    var biometryEnabled: Bool {
        get {
            return localStorage.isBiometricOn
        }
        set {
            localStorage.isBiometricOn = newValue
        }
    }

    func store(pin: String) throws {
        try secureStorage.set(pin: pin)
        isPinSetSubject.onNext(true)
    }

    func validate(pin: String) -> Bool {
        return secureStorage.pin == pin
    }

    func clear() throws {
        try secureStorage.set(pin: nil)
        localStorage.isBiometricOn = false
    }

    var isPinSetObservable: Observable<Bool> {
        return isPinSetSubject.asObservable()
    }

}
