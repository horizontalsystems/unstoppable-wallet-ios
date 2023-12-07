import Combine

class SwitchAccountViewModel: ObservableObject {
    private let accountManager = App.shared.accountManager

    let regularViewItems: [ViewItem]
    let watchViewItems: [ViewItem]

    init() {
        let activeAccount = accountManager.activeAccount

        let sortedAccounts = accountManager.accounts.sorted { $0.name.lowercased() < $1.name.lowercased() }

        regularViewItems = sortedAccounts.filter { !$0.watchAccount }.map { Self.viewItem(account: $0, activeAccount: activeAccount) }
        watchViewItems = sortedAccounts.filter(\.watchAccount).map { Self.viewItem(account: $0, activeAccount: activeAccount) }
    }

    private static func viewItem(account: Account, activeAccount: Account?) -> ViewItem {
        ViewItem(
            accountId: account.id,
            title: account.name,
            subtitle: account.type.detailedDescription,
            selected: account == activeAccount
        )
    }
}

extension SwitchAccountViewModel {
    func onSelect(accountId: String) {
        accountManager.set(activeAccountId: accountId)

        stat(page: .switchWallet, event: .select(entity: .wallet))
    }
}

extension SwitchAccountViewModel {
    struct ViewItem {
        let accountId: String
        let title: String
        let subtitle: String
        let selected: Bool
    }
}
