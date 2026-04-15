import Combine
import Foundation

class BackupSelectContentViewModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let contactManager = Core.shared.contactManager
    private let watchlistManager = Core.shared.watchlistManager
    private let evmSyncSourceManager = Core.shared.evmSyncSourceManager
    private let moneroNodeManager = Core.shared.moneroNodeManager
    private let zanoNodeManager = Core.shared.zanoNodeManager
    private let cloudBackupManager = Core.shared.cloudBackupManager

    let walletItems: [BackupModule.WalletItem]
    let dataItems: [BackupModule.DataItem]

    @Published var selectedWalletIds: Set<String>
    @Published var selectedDataSections: Set<BackupSection>

    init(selectedAccountIds: Set<String>) {
        walletItems = Self.buildWalletItems(
            accountManager: accountManager,
            cloudBackupManager: cloudBackupManager
        )
        dataItems = Self.buildDataItems(
            contactManager: contactManager,
            watchlistManager: watchlistManager,
            evmSyncSourceManager: evmSyncSourceManager,
            moneroNodeManager: moneroNodeManager,
            zanoNodeManager: zanoNodeManager
        )

        selectedWalletIds = selectedAccountIds.intersection(Set(walletItems.map(\.accountId)))
        selectedDataSections = Set(dataItems.map(\.section))
    }

    private static func buildWalletItems(accountManager: AccountManager, cloudBackupManager: CloudBackupManager) -> [BackupModule.WalletItem] {
        let all = accountManager.accounts.sorted { $0.name.lowercased() < $1.name.lowercased() }
        let regular = all.filter { !$0.watchAccount }
        let watch = all.filter(\.watchAccount)

        return (regular + watch).map { account in
            var cautionType: CautionType?
            if account.nonStandard {
                cautionType = .error
            } else if !(account.backedUp || cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())) {
                cautionType = .error
            }

            return BackupModule.WalletItem(
                accountId: account.id,
                name: account.name,
                subtitle: account.type.detailedDescription,
                isWatch: account.watchAccount,
                cautionType: cautionType
            )
        }
    }

    private static func buildDataItems(
        contactManager: ContactBookManager,
        watchlistManager: WatchlistManager,
        evmSyncSourceManager: EvmSyncSourceManager,
        moneroNodeManager: MoneroNodeManager,
        zanoNodeManager: ZanoNodeManager
    ) -> [BackupModule.DataItem] {
        var items: [BackupModule.DataItem] = []

        let contactsCount = contactManager.all?.count ?? 0
        if contactsCount > 0 {
            items.append(.init(
                section: .contacts,
                title: "backup_content.data.contacts.title".localized,
                subtitle: "backup_content.data.contacts.subtitle".localized(contactsCount)
            ))
        }

        let favoritesCount = watchlistManager.coinUids.count
        if favoritesCount > 0 {
            items.append(.init(
                section: .favourites,
                title: "backup_content.data.favorites.title".localized,
                subtitle: "backup_content.data.favorites.subtitle".localized(favoritesCount)
            ))
        }

        let rpcCount = evmSyncSourceManager.customSyncSources(blockchainType: nil).count
            + moneroNodeManager.customNodes(blockchainType: nil).count
            + zanoNodeManager.customNodeRecords.count
        if rpcCount > 0 {
            items.append(.init(
                section: .customRpc,
                title: "backup_content.data.custom_rpc.title".localized,
                subtitle: "backup_content.data.custom_rpc.subtitle".localized(rpcCount)
            ))
        }

        items.append(.init(
            section: .preferences,
            title: "backup_content.data.preferences.title".localized,
            subtitle: "backup_content.data.preferences.subtitle".localized
        ))

        return items
    }
}
