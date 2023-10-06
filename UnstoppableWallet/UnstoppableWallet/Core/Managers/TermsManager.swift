import Combine
import HsExtensions
import StorageKit

class TermsManager {
    private let keyTermsAccepted = "key_terms_accepted"
    private let storage: StorageKit.ILocalStorage

    @DistinctPublished var termsAccepted: Bool

    init(storage: StorageKit.ILocalStorage) {
        self.storage = storage

        termsAccepted = storage.value(for: keyTermsAccepted) ?? false
    }
}

extension TermsManager {
    func setTermsAccepted() {
        storage.set(value: true, for: keyTermsAccepted)
        termsAccepted = true
    }
}
