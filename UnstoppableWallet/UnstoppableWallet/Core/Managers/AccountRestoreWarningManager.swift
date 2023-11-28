import Foundation
import RxSwift

class AccountRestoreWarningManager {
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

    var hasNonStandardObservable: Observable<Bool> {
        accountManager.accountsObservable.map { !$0.filter(\.nonStandard).isEmpty }
    }

    var hasNonRecommended: Bool {
        !accountManager.accounts.filter(\.nonRecommended).isEmpty
    }

    var hasNonRecommendedObservable: Observable<Bool> {
        accountManager.accountsObservable.map { !$0.filter(\.nonStandard).isEmpty }
    }

    func removeIgnoreWarning(account: Account) {
        userDefaultsStorage.set(value: nil as Bool?, for: AccountRestoreWarningFactory.keyAccountWarningPrefix + account.id)
    }

    func setIgnoreWarning(account: Account) {
        userDefaultsStorage.set(value: true, for: AccountRestoreWarningFactory.keyAccountWarningPrefix + account.id)
    }
}

class AccountRestoreWarningFactory {
    static let keyAccountWarningPrefix = "wallet-ignore-non-recommended"
    private let userDefaultsStorage: UserDefaultsStorage
    private let languageManager: LanguageManager

    init(userDefaultsStorage: UserDefaultsStorage, languageManager: LanguageManager) {
        self.userDefaultsStorage = userDefaultsStorage
        self.languageManager = languageManager
    }

    func caution(account: Account, canIgnoreActiveAccountWarning: Bool) -> CancellableTitledCaution? {
        if account.nonStandard {
            return CancellableTitledCaution(title: "note".localized, text: "restore.error.non_standard.description".localized, type: .error, cancellable: false)
        } else if account.nonRecommended {
            if canIgnoreActiveAccountWarning, userDefaultsStorage.value(for: Self.keyAccountWarningPrefix + account.id) ?? false {
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
