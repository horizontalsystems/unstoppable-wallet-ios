import Combine
import Foundation

class RestoreFileConfigurationViewModel: ObservableObject {
    private let cloudBackupManager: CloudBackupManager
    private let appBackupProvider: AppBackupProvider
    private let contactBookManager: ContactBookManager
    private let rawBackup: RawFullBackup

    private let showMergeAlertSubject = PassthroughSubject<Void, Never>()
    private let finishedSubject = PassthroughSubject<Bool, Never>()

    let statPage: StatPage

    init(cloudBackupManager: CloudBackupManager, appBackupProvider: AppBackupProvider, contactBookManager: ContactBookManager, statPage: StatPage, rawBackup: RawFullBackup) {
        self.cloudBackupManager = cloudBackupManager
        self.appBackupProvider = appBackupProvider
        self.contactBookManager = contactBookManager
        self.statPage = statPage
        self.rawBackup = rawBackup
    }

    private func item(account: Account) -> BackupModule.AccountItem {
        var alertSubtitle: String?
        let hasAlertDescription = !(account.backedUp || cloudBackupManager.backedUp(uniqueId: account.type.uniqueId()))
        if account.nonStandard {
            alertSubtitle = "manage_accounts.migration_required".localized
        } else if hasAlertDescription {
            alertSubtitle = "manage_accounts.backup_required".localized
        }

        let showAlert = alertSubtitle != nil || account.nonRecommended

        let cautionType: CautionType? = showAlert ? .error : .none
        let description = alertSubtitle ?? account.type.detailedDescription

        return BackupModule.AccountItem(
            accountId: account.id,
            name: account.name,
            description: description,
            cautionType: cautionType
        )
    }
}

extension RestoreFileConfigurationViewModel {
    var accountItems: [BackupModule.AccountItem] {
        rawBackup
            .accounts
            .filter { !$0.account.watchAccount }
            .sorted { wallet, wallet2 in wallet.account.name.lowercased() < wallet2.account.name.lowercased() }
            .map { item(account: $0.account) }
    }

    var otherItems: [BackupModule.ContentItem] {
        let contactAddressCount = rawBackup.contacts.count
        let watchAccounts = rawBackup
            .accounts
            .filter(\.account.watchAccount)

        return items(
            watchAccountCount: watchAccounts.count,
            watchlistCount: rawBackup.watchlistIds.count,
            contactAddressCount: contactAddressCount,
            customEvmSyncSources: rawBackup.customSyncSources.count,
            customMoneroNodes: rawBackup.customMoneroNodes.count
        )
    }

    private func items(watchAccountCount: Int, watchlistCount: Int, contactAddressCount: Int, customEvmSyncSources: Int, customMoneroNodes: Int) -> [BackupModule.ContentItem] {
        var items = [BackupModule.ContentItem]()

        if watchAccountCount != 0 {
            items.append(.init(
                title: "backup_app.backup_list.other.watch_account.title".localized,
                value: watchAccountCount.description
            ))
        }

        if watchlistCount != 0 {
            items.append(.init(
                title: "backup_app.backup_list.other.watchlist.title".localized,
                value: watchlistCount.description
            ))
        }

        if contactAddressCount != 0 {
            items.append(.init(
                title: "backup_app.backup_list.other.contacts.title".localized,
                value: contactAddressCount.description
            ))
        }

        if customEvmSyncSources != 0 {
            items.append(.init(
                title: "backup_app.backup_list.other.custom_evm_sync_sources.title".localized,
                value: customEvmSyncSources.description
            ))
        }
        if customMoneroNodes != 0 {
            items.append(.init(
                title: "backup_app.backup_list.other.custom_monero_nodes.title".localized,
                value: customMoneroNodes.description
            ))
        }
        items.append(.init(
            title: "backup_app.backup_list.other.app_settings.title".localized,
            description: "backup_app.backup_list.other.app_settings.description".localized
        ))

        return items
    }

    func onTapRestore() {
        if contactBookManager.state.data?.contacts.isEmpty ?? true {
            restore()
        } else {
            showMergeAlertSubject.send()
        }
    }

    func restore() {
        stat(page: statPage, event: .importFull)
        appBackupProvider.restore(raw: rawBackup)
        finishedSubject.send(true)
    }

    var showMergeAlertPublisher: AnyPublisher<Void, Never> {
        showMergeAlertSubject.eraseToAnyPublisher()
    }

    var finishedPublisher: AnyPublisher<Bool, Never> {
        finishedSubject.eraseToAnyPublisher()
    }
}
