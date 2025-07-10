import Combine
import Foundation

class AccountWarningViewModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let accountRestoreWarningManager = Core.shared.accountRestoreWarningManager
    private let languageManager = LanguageManager.shared
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var item: Item?

    private let predefinedAccount: Account?
    private let canIgnore: Bool

    init(predefinedAccount: Account? = nil, canIgnore: Bool) {
        self.predefinedAccount = predefinedAccount
        self.canIgnore = canIgnore

        if predefinedAccount == nil {
            accountManager.activeAccountPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.syncItem() }
                .store(in: &cancellables)
        }

        syncItem()
    }

    private func syncItem() {
        item = resolveItem()
    }

    private func resolveItem() -> Item? {
        guard let account = predefinedAccount ?? accountManager.activeAccount else {
            return nil
        }

        if account.nonStandard {
            return Item(
                caution: CautionNew(title: "note".localized, text: "restore.error.non_standard.description".localized, type: .error),
                url: warningUrl(path: "/management/migration_required.md"),
                canIgnore: false
            )
        } else if account.nonRecommended {
            if canIgnore, accountRestoreWarningManager.getIgnoreWarning(account: account) {
                return nil
            }

            return Item(
                caution: CautionNew(title: "note".localized, text: "restore.warning.non_recommended.description".localized, type: .warning),
                url: warningUrl(path: "/management/migration_recommended.md"),
                canIgnore: canIgnore
            )
        } else {
            return nil
        }
    }

    func warningUrl(path: String) -> URL? {
        URL(string: "faq/\(languageManager.currentLanguage)\(path)", relativeTo: AppConfig.faqIndexUrl)
    }
}

extension AccountWarningViewModel {
    func onIgnore() {
        guard let account = predefinedAccount ?? accountManager.activeAccount else {
            return
        }

        accountRestoreWarningManager.setIgnoreWarning(account: account)
        syncItem()
    }
}

extension AccountWarningViewModel {
    struct Item: Equatable {
        let caution: CautionNew
        let url: URL?
        let canIgnore: Bool
    }
}
