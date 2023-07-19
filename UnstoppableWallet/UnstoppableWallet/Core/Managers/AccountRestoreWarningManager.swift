import Foundation
import RxSwift
import StorageKit
import LanguageKit

class AccountRestoreWarningManager {
    private let accountManager: AccountManager
    private let localStorage: ILocalStorage

    init(accountManager: AccountManager, localStorage: ILocalStorage) {
        self.accountManager = accountManager
        self.localStorage = localStorage
    }

}

extension AccountRestoreWarningManager {

    var hasNonStandard: Bool {
        !accountManager.accounts.filter { $0.nonStandard }.isEmpty
    }

    var hasNonStandardObservable: Observable<Bool> {
        accountManager.accountsObservable.map { !$0.filter { $0.nonStandard }.isEmpty }
    }

    var hasNonRecommended: Bool {
        !accountManager.accounts.filter { $0.nonRecommended }.isEmpty
    }

    var hasNonRecommendedObservable: Observable<Bool> {
        accountManager.accountsObservable.map { !$0.filter { $0.nonStandard }.isEmpty }
    }

    func removeIgnoreWarning(account: Account) {
        localStorage.set(value: nil as Bool?, for: AccountRestoreWarningFactory.keyAccountWarningPrefix + account.id)
    }

    func setIgnoreWarning(account: Account) {
        localStorage.set(value: true, for: AccountRestoreWarningFactory.keyAccountWarningPrefix + account.id)
    }

}

class AccountRestoreWarningFactory {
    static let keyAccountWarningPrefix = "wallet-ignore-non-recommended"
    private let localStorage: ILocalStorage
    private let languageManager: LanguageManager

    init(localStorage: ILocalStorage, languageManager: LanguageManager) {
        self.localStorage = localStorage
        self.languageManager = languageManager
    }

    func caution(account: Account, canIgnoreActiveAccountWarning: Bool) -> CancellableTitledCaution? {
        if account.nonStandard {
            return CancellableTitledCaution(title: "note".localized, text: "restore.error.non_standard.description".localized, type: .error, cancellable: false)
        } else if account.nonRecommended {
            if canIgnoreActiveAccountWarning, localStorage.value(for: Self.keyAccountWarningPrefix + account.id) ?? false {
                return nil
            }

            return CancellableTitledCaution(title: "note".localized, text:  "restore.warning.non_recommended.description".localized, type: .warning, cancellable: canIgnoreActiveAccountWarning)
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