import RxSwift
import RxRelay
import StorageKit

class TermsManager {
    private let keyTermsAccepted = "key_terms_accepted"
    private let storage: StorageKit.ILocalStorage

    private let termsAcceptedRelay = PublishRelay<Bool>()

    init(storage: StorageKit.ILocalStorage) {
        self.storage = storage
    }

}

extension TermsManager {

    var termsAccepted: Bool {
        storage.value(for: keyTermsAccepted) ?? false
    }

    var termsAcceptedObservable: Observable<Bool> {
        termsAcceptedRelay.asObservable()
    }

    func setTermsAccepted() {
        storage.set(value: true, for: keyTermsAccepted)
        termsAcceptedRelay.accept(true)
    }

}
