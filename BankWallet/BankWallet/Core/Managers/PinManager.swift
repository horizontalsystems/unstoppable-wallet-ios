import RxSwift

class PinManager {
    private let secureStorage: ISecureStorage

    private let isPinSetSubject = PublishSubject<Bool>()

    init(secureStorage: ISecureStorage) {
        self.secureStorage = secureStorage
    }

}

extension PinManager: IPinManager {

    var isPinSet: Bool {
        return secureStorage.pin != nil
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
    }

    var isPinSetObservable: Observable<Bool> {
        return isPinSetSubject.asObservable()
    }

}
