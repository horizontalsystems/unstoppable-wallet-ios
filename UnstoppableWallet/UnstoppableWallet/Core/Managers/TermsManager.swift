import Combine
import HsExtensions

class TermsManager {
    private let keyTermsAccepted = "key_terms_accepted"
    private let userDefaultsStorage: UserDefaultsStorage

    @DistinctPublished var termsAccepted: Bool

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        termsAccepted = userDefaultsStorage.value(for: keyTermsAccepted) ?? false
    }
}

extension TermsManager {
    func setTermsAccepted() {
        userDefaultsStorage.set(value: true, for: keyTermsAccepted)
        termsAccepted = true
    }
}
