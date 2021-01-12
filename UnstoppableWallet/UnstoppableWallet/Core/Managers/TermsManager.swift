import RxSwift
import StorageKit

class TermsManager {
    private let storage: StorageKit.ILocalStorage

    private let subject = PublishSubject<Bool>()

    private let termIds = ["academy", "backup", "owner", "recover", "phone", "root", "bugs", "pin"]

    init(storage: StorageKit.ILocalStorage) {
        self.storage = storage
    }

    private func storageKey(id: String) -> String {
        "key_terms_\(id)"
    }

    private func term(id: String) -> Term {
        Term(
                id: id,
                accepted: storage.value(for: storageKey(id: id)) ?? false
        )
    }

    private func notifyIfRequired(termsAcceptedOld: Bool) {
        let termsAcceptedNew = termsAccepted

        if termsAcceptedOld != termsAcceptedNew {
            subject.onNext(termsAcceptedNew)
        }
    }

}

extension TermsManager: ITermsManager {

    var terms: [Term] {
        termIds.map { term(id: $0) }
    }

    var termsAccepted: Bool {
        terms.allSatisfy { $0.accepted }
    }

    var termsAcceptedObservable: Observable<Bool> {
        subject.asObservable()
    }

    func update(term: Term) {
        let termsAcceptedOld = termsAccepted

        storage.set(value: term.accepted, for: storageKey(id: term.id))

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.notifyIfRequired(termsAcceptedOld: termsAcceptedOld)
        }
    }

}
