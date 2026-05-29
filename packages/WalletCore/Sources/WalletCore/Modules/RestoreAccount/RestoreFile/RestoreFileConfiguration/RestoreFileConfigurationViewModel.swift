import Combine
import Foundation

class RestoreFileConfigurationViewModel: ObservableObject {
    private let cloudBackupManager: CloudBackupManager
    private let appBackupProvider: AppBackupProvider
    private let contactBookManager: ContactBookManager
    private let rawBackup: RawFullBackup
    private let backupName: String

    private let showMergeAlertSubject = PassthroughSubject<Void, Never>()
    private let finishedSubject = PassthroughSubject<Bool, Never>()

    let statPage: StatPage
    let walletItems: [BackupModule.WalletItem]
    let dataItems: [BackupModule.DataItem]

    @Published var selectedWalletIds: Set<String>
    @Published var selectedDataSections: Set<BackupSection>

    init(cloudBackupManager: CloudBackupManager, appBackupProvider: AppBackupProvider, contactBookManager: ContactBookManager, statPage: StatPage, rawBackup: RawFullBackup, backupName: String) {
        self.cloudBackupManager = cloudBackupManager
        self.appBackupProvider = appBackupProvider
        self.contactBookManager = contactBookManager
        self.statPage = statPage
        self.rawBackup = rawBackup
        self.backupName = backupName

        walletItems = Self.buildWalletItems(rawBackup: rawBackup)
        dataItems = Self.buildDataItems(rawBackup: rawBackup)

        selectedWalletIds = Set(walletItems.map(\.accountId))
        selectedDataSections = Set(dataItems.map(\.section))
    }

    private static func buildWalletItems(rawBackup: RawFullBackup) -> [BackupModule.WalletItem] {
        let sorted = rawBackup.accounts.sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }
        let regular = sorted.filter { !$0.account.watchAccount }
        let watch = sorted.filter(\.account.watchAccount)

        return (regular + watch).map { raw in
            BackupModule.WalletItem(
                accountId: raw.account.id,
                name: raw.account.name,
                subtitle: raw.account.type.detailedDescription,
                isWatch: raw.account.watchAccount,
                cautionType: nil
            )
        }
    }

    private static func buildDataItems(rawBackup: RawFullBackup) -> [BackupModule.DataItem] {
        let sections = rawBackup.sections ?? Set(BackupSection.allCases)
        var items: [BackupModule.DataItem] = []

        if sections.contains(.contacts), !rawBackup.contacts.isEmpty {
            items.append(.init(
                section: .contacts,
                title: "backup_content.data.contacts.title".localized,
                subtitle: "backup_content.data.contacts.subtitle".localized(rawBackup.contacts.count)
            ))
        }

        if sections.contains(.favourites), !rawBackup.watchlistIds.isEmpty {
            items.append(.init(
                section: .favourites,
                title: "backup_content.data.favorites.title".localized,
                subtitle: "backup_content.data.favorites.subtitle".localized(rawBackup.watchlistIds.count)
            ))
        }

        if sections.contains(.customRpc) {
            let rpcCount = rawBackup.customSyncSources.count
                + rawBackup.customMoneroNodes.count
                + rawBackup.customZanoNodes.count
            if rpcCount > 0 {
                items.append(.init(
                    section: .customRpc,
                    title: "backup_content.data.custom_rpc.title".localized,
                    subtitle: "backup_content.data.custom_rpc.subtitle".localized(rpcCount)
                ))
            }
        }

        if sections.contains(.preferences) {
            items.append(.init(
                section: .preferences,
                title: "backup_content.data.preferences.title".localized,
                subtitle: "backup_content.data.preferences.subtitle".localized
            ))
        }

        return items
    }
}

extension RestoreFileConfigurationViewModel {
    var backupTitle: String { backupName }

    func onTapRestore() {
        if selectedDataSections.contains(.contacts), !(contactBookManager.state.data?.contacts.isEmpty ?? true) {
            showMergeAlertSubject.send()
        } else {
            restore()
        }
    }

    func restore() {
        stat(page: statPage, event: .importFull)
        appBackupProvider.restore(
            raw: rawBackup,
            accountIds: selectedWalletIds,
            sections: selectedDataSections
        )
        finishedSubject.send(true)
    }

    var showMergeAlertPublisher: AnyPublisher<Void, Never> {
        showMergeAlertSubject.eraseToAnyPublisher()
    }

    var finishedPublisher: AnyPublisher<Bool, Never> {
        finishedSubject.eraseToAnyPublisher()
    }
}
