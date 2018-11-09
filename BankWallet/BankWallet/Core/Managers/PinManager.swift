import RxSwift

class PinManager {
    private let disposeBag = DisposeBag()

    private let secureStorage: ISecureStorage
    private let wordsManager: IWordsManager

    init(secureStorage: ISecureStorage, wordsManager: IWordsManager) {
        self.secureStorage = secureStorage
        self.wordsManager = wordsManager

        wordsManager.loggedInSubject
                .subscribe(onNext: { [weak self] loggedIn in
                    if !loggedIn {
                        self?.clearPin()
                    }
                })
                .disposed(by: disposeBag)
    }

    private func clearPin() {
        try? secureStorage.set(pin: nil)
    }

}

extension PinManager: IPinManager {

    var isPinSet: Bool {
        return secureStorage.pin != nil
    }

    func store(pin: String?) throws {
        try secureStorage.set(pin: pin)
    }

    func validate(pin: String) -> Bool {
        return secureStorage.pin == pin
    }

}
