import Combine
import Foundation

class AccountWarningViewModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let accountRestoreWarningManager = Core.shared.accountRestoreWarningManager
    private let languageManager = LanguageManager.shared
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var item: Item?

    private let predefinedAccount: Account?
    private let ignoreType: IgnoreType

    init(predefinedAccount: Account? = nil, ignoreType: IgnoreType) {
        self.predefinedAccount = predefinedAccount
        self.ignoreType = ignoreType

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
            var description = AttributedString("restore.error.non_standard.description".localized)
            var underlined = AttributedString("restore.error.non_standard.link".localized)
            underlined.underlineStyle = .single

            description.append(underlined)

            return Item(
                alertItem: .init(text: .attributed(description), type: .critical),
                url: warningUrl(path: "/management/migration_required.md"),
                canIgnore: false
            )
        } else if account.nonRecommended {
            switch ignoreType {
            case .always: return nil
            case .auto:
                if accountRestoreWarningManager.getIgnoreWarning(account: account) {
                    return nil
                }
            case .none: ()
            }

            var description = AttributedString("restore.warning.non_recommended.description".localized)
            var underlined = AttributedString("restore.error.non_standard.link".localized)
            underlined.underlineStyle = .single

            description.append(underlined)

            return Item(
                alertItem: .init(text: .attributed(description)),
                url: warningUrl(path: "/management/migration_recommended.md"),
                canIgnore: true
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
    enum IgnoreType {
        case always
        case auto
        case none
    }

    struct Item: Equatable {
        let alertItem: AlertCardViewItem
        let url: URL?
        let canIgnore: Bool
    }
}
