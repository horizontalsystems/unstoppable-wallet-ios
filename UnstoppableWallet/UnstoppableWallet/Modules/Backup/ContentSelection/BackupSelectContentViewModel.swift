import Combine
import Foundation

class BackupSelectContentViewModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let contactManager = Core.shared.contactManager
    private let watchlistManager = Core.shared.watchlistManager
    private let evmSyncSourceManager = Core.shared.evmSyncSourceManager
    private let moneroNodeManager = Core.shared.moneroNodeManager
    private let cloudBackupManager = Core.shared.cloudBackupManager

    @Published var accountItems: [BackupModule.AccountItem] = []
    @Published var contentItems: [BackupModule.ContentItem] = []
    @Published var selectedAccountIds: Set<String>

    init(selectedAccountIds: Set<String>) {
        self.selectedAccountIds = selectedAccountIds

        accountItems = buildAccountItems()
        contentItems = buildContentItems()
    }

    private func buildAccountItems() -> [BackupModule.AccountItem] {
        accountManager.accounts
            .filter { !$0.watchAccount }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
            .map { account in
                var cautionType: CautionType?
                let description: String

                if account.nonStandard {
                    cautionType = .error
                    description = "manage_accounts.migration_required".localized
                } else if !(account.backedUp || cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())) {
                    cautionType = .error
                    description = "manage_accounts.backup_required".localized
                } else {
                    description = account.type.detailedDescription
                }

                return BackupModule.AccountItem(
                    accountId: account.id,
                    name: account.name,
                    description: description,
                    cautionType: cautionType
                )
            }
    }

    private func buildContentItems() -> [BackupModule.ContentItem] {
        var items: [BackupModule.ContentItem] = []

        let watchAccountCount = accountManager.accounts.filter(\.watchAccount).count
        if watchAccountCount > 0 {
            items.append(BackupModule.ContentItem(
                title: "backup_app.backup_list.other.watch_account.title".localized,
                value: watchAccountCount.description
            ))
        }

        let watchlistCount = watchlistManager.coinUids.count
        if watchlistCount > 0 {
            items.append(BackupModule.ContentItem(
                title: "backup_app.backup_list.other.watchlist.title".localized,
                value: watchlistCount.description
            ))
        }

        let contactsCount = contactManager.all?.count ?? 0
        if contactsCount > 0 {
            items.append(BackupModule.ContentItem(
                title: "backup_app.backup_list.other.contacts.title".localized,
                value: contactsCount.description
            ))
        }

        let customEvmSyncSources = evmSyncSourceManager.customSyncSources(blockchainType: nil).count
        if customEvmSyncSources > 0 {
            items.append(BackupModule.ContentItem(
                title: "backup_app.backup_list.other.custom_evm_sync_sources.title".localized,
                value: customEvmSyncSources.description
            ))
        }

        let customMoneroNodes = moneroNodeManager.customNodes(blockchainType: nil).count
        if customMoneroNodes > 0 {
            items.append(BackupModule.ContentItem(
                title: "backup_app.backup_list.other.custom_monero_nodes.title".localized,
                value: customMoneroNodes.description
            ))
        }

        items.append(BackupModule.ContentItem(
            title: "backup_app.backup_list.other.app_settings.title".localized,
            description: "backup_app.backup_list.other.app_settings.description".localized
        ))

        return items
    }

    func toggle(accountId: String) {
        if selectedAccountIds.contains(accountId) {
            selectedAccountIds.remove(accountId)
        } else {
            selectedAccountIds.insert(accountId)
        }
    }
}
