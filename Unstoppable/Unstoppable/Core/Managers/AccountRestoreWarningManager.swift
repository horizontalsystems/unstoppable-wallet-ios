import Combine
import Foundation

class AccountRestoreWarningManager {
    private static let keyAccountWarningPrefix = "wallet-ignore-non-recommended"

    private let accountManager: AccountManager
    private let userDefaultsStorage: UserDefaultsStorage

    init(accountManager: AccountManager, userDefaultsStorage: UserDefaultsStorage) {
        self.accountManager = accountManager
        self.userDefaultsStorage = userDefaultsStorage
    }
}

extension AccountRestoreWarningManager {
    var hasNonStandard: Bool {
        !accountManager.accounts.filter(\.nonStandard).isEmpty
    }

    var hasNonStandardPublisher: AnyPublisher<Bool, Never> {
        accountManager.accountsPublisher.map { !$0.filter(\.nonStandard).isEmpty }.eraseToAnyPublisher()
    }

    var hasNonRecommended: Bool {
        !accountManager.accounts.filter(\.nonRecommended).isEmpty
    }

    func getIgnoreWarning(account: Account) -> Bool {
        userDefaultsStorage.value(for: Self.keyAccountWarningPrefix + account.id) ?? false
    }

    func removeIgnoreWarning(account: Account) {
        userDefaultsStorage.set(value: nil as Bool?, for: Self.keyAccountWarningPrefix + account.id)
    }

    func setIgnoreWarning(account: Account) {
        userDefaultsStorage.set(value: true, for: Self.keyAccountWarningPrefix + account.id)
    }
}

class AccountRestoreWarningFactory {
    private let accountRestoreWarningManager = Core.shared.accountRestoreWarningManager
    private let languageManager = LanguageManager.shared

    func caution(account: Account, canIgnoreActiveAccountWarning: Bool) -> CancellableTitledCaution? {
        if account.nonStandard {
            return CancellableTitledCaution(title: "note".localized, text: "restore.error.non_standard.description".localized, type: .error, cancellable: false)
        } else if account.nonRecommended {
            if canIgnoreActiveAccountWarning, accountRestoreWarningManager.getIgnoreWarning(account: account) {
                return nil
            }

            return CancellableTitledCaution(title: "note".localized, text: "restore.warning.non_recommended.description".localized, type: .warning, cancellable: canIgnoreActiveAccountWarning)
        }
        return nil
    }

    func warningUrl(account: Account) -> URL? {
        let faqIndexUrl = AppConfig.faqIndexUrl
        var fileUrl = "faq/\(languageManager.currentLanguage)/"

        if account.nonStandard {
            fileUrl += "management/migration_required.md"
        } else if account.nonRecommended {
            fileUrl += "management/migration_recommended.md"
        }

        return URL(string: fileUrl, relativeTo: faqIndexUrl)
    }
}
