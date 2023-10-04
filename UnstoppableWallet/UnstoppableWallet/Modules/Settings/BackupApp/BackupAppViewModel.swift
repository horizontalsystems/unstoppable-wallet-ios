import Combine
import ComponentKit
import Foundation

class BackupAppViewModel: ObservableObject {
    static let backupNamePrefix = "App Backup"
    let accountManager: AccountManager
    let contactManager: ContactBookManager
    let cloudBackupManager: CloudBackupManager
    let favoritesManager: FavoritesManager
    let evmSyncSourceManager: EvmSyncSourceManager

    private var cancellables = Set<AnyCancellable>()

    // Type ViewModel
    @Published var cloudAvailable: Bool
    @Published var destination: BackupAppModule.Destination? {
        didSet {
            // need to reset future fields:
            name = nextName
            password = AppConfig.defaultPassphrase
            confirm = AppConfig.defaultPassphrase

            accountItems = accounts(watch: false)
                .map { item(account: $0) }

            otherItems = getOtherItems()
            selected = accountIds.reduce(into: [:]) { $0[$1] = true }
        }
    }

    // Configuration ViewModel
    @Published var selected: [String: Bool] = [:]
    @Published var accountItems: [AccountItem] = []
    @Published var otherItems: [Item] = []
    @Published var disclaimerPushed = false {
        didSet {
            // need to reset future fields:
            name = nextName
            password = AppConfig.defaultPassphrase
            confirm = AppConfig.defaultPassphrase
        }
    }

    // Disclaimer ViewModel
    @Published var namePushed = false {
        didSet {
            // need to reset future fields:
            name = nextName
            password = AppConfig.defaultPassphrase
            confirm = AppConfig.defaultPassphrase
        }
    }

    // Name ViewModel
    @Published var nameCautionState: CautionState = .none
    @Published var name: String = "" {
        didSet {
            validateName()
        }
    }
    @Published var passwordPushed = false {
        didSet {
            // need to reset future fields:
            password = AppConfig.defaultPassphrase
            confirm = AppConfig.defaultPassphrase
        }
    }

    // Password ViewModel
    @Published var passwordCautionState: CautionState = .none
    @Published var password: String = AppConfig.defaultPassphrase {
        didSet {
            validatePasswords()
        }
    }

    @Published var confirmCautionState: CautionState = .none
    @Published var confirm: String = AppConfig.defaultPassphrase {
        didSet {
            validatePasswords()
        }
    }

    @Published var passwordButtonDisabled = true
    @Published var passwordButtonProcessing = false

    private var dismissSubject = PassthroughSubject<Void, Never>()
    @Published var sharePresented: URL?

    init(accountManager: AccountManager, contactManager: ContactBookManager, cloudBackupManager: CloudBackupManager, favoritesManager: FavoritesManager, evmSyncSourceManager: EvmSyncSourceManager) {
        self.accountManager = accountManager
        self.contactManager = contactManager
        self.cloudBackupManager = cloudBackupManager
        self.favoritesManager = favoritesManager
        self.evmSyncSourceManager = evmSyncSourceManager

        cloudAvailable = cloudBackupManager.iCloudUrl != nil
        cloudBackupManager.$state
            .sink(receiveValue: { [weak self] state in
                switch state {
                case .error: self?.cloudAvailable = false
                default: self?.cloudAvailable = true
                }
            })
            .store(in: &cancellables)

        accountItems = accounts(watch: false)
            .map { item(account: $0) }

        otherItems = getOtherItems()
        selected = accountIds.reduce(into: [:]) { $0[$1] = true }
        name = nextName

        validatePasswords()
    }
}

// Account Page ViewModel
extension BackupAppViewModel {
    private func accounts(watch: Bool) -> [Account] {
        accountManager
            .accounts
            .filter { $0.watchAccount == watch }
    }

    private var accountIds: [String] {
        accounts(watch: false)
            .map { $0.id }
    }

    private func item(account: Account) -> AccountItem {
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

        return AccountItem(
            accountId: account.id,
            name: account.name,
            description: description,
            cautionType: cautionType
        )
    }

    private func getOtherItems() -> [Item] {
        var items = [Item]()

        let watchAccountCount = accounts(watch: true).count
        if watchAccountCount != 0 {
            items.append(Item(
                title: "backup_list.other.watch_account.title".localized,
                description: "backup_list.other.watch_account.description".localized(watchAccountCount)
            ))
        }

        let watchlistCount = favoritesManager.allCoinUids.count
        if watchlistCount != 0 {
            items.append(Item(
                title: "backup_list.other.watchlist.title".localized,
                description: "backup_list.other.watchlist.description".localized(watchlistCount)
            ))
        }

        let contacts = contactManager.all ?? []
        let contactAddressCount = contacts.reduce(into: 0) { $0 += $1.addresses.count }
        if contactAddressCount != 0 {
            items.append(Item(
                title: "backup_list.other.contacts.title".localized,
                description: "backup_list.other.contacts.description".localized(contactAddressCount)
            ))
        }

        let blockchainSourcesCount = evmSyncSourceManager.customSyncSources(blockchainType: nil).count
        if blockchainSourcesCount != 0 {
            items.append(Item(
                title: "backup_list.other.blockchain_settings.title".localized,
                description: "backup_list.other.blockchain_settings.description".localized(blockchainSourcesCount)
            ))
        }
        items.append(Item(
            title: "backup_list.other.app_settings.title".localized,
            description: "backup_list.other.app_settings.description".localized
        ))

        return items
    }

    var configuration: [AppBackupProvider.Field] {
        var fields = [AppBackupProvider.Field.settings]

        var accountIds = accounts(watch: true).map { $0.id }
        selected.forEach { id, selected in
            if selected {
                accountIds.append(id)
            }
        }

        fields.append(.accounts(ids: accountIds))

        let contacts = contactManager.all ?? []
        if contacts.count != 0 {
            fields.append(.contacts)
        }

        if !favoritesManager.allCoinUids.isEmpty {
            fields.append(.watchlist)
        }

        return fields
    }
}

extension BackupAppViewModel {
    func toggle(item: AccountItem) {
        selected[item.accountId]?.toggle()
    }
}

// Backup Name VieeModel
extension BackupAppViewModel {
    var nextName: String {
        let name = { [Self.backupNamePrefix, $0].joined(separator: " ") }
        switch destination {
        case .cloud:
            let exists = cloudBackupManager
                .existFilenames
                .filter { $0.hasPrefix(Self.backupNamePrefix) }
                .sorted()
            for i in 1 ..< exists.count + 1 {
                let newName = name(i.description)
                if !exists.contains(where: { $0.lowercased() == newName.lowercased() }) {
                    return newName
                }
            }
            return name((exists.count + 1).description)
        default:
            return name("1")
        }
    }

    func validateName() {
        if name.isEmpty {
            nameCautionState = .caution(.init(text: NameError.empty.localizedDescription, type: .error))
        } else if destination == .cloud, cloudBackupManager.existFilenames.contains(where: { $0.lowercased() == name.lowercased() }) {
            nameCautionState = .caution(.init(text: NameError.alreadyExist.localizedDescription, type: .error))
        } else {
            nameCautionState = .none
        }
    }

    func validatePasswords() {
        var buttonDisabled = false
        if password.isEmpty {
            buttonDisabled = true
            confirmCautionState = .none
        } else {
            do {
                try BackupCrypto.validate(passphrase: password)
                passwordCautionState = .none
            } catch {
                passwordCautionState = .caution(.init(text: error.localizedDescription, type: .error))
                buttonDisabled = true
            }
        }

        if confirm.isEmpty {
            buttonDisabled = true
            confirmCautionState = .none
        } else {
            do {
                try BackupCrypto.validate(passphrase: confirm)
                if password != confirm {
                    buttonDisabled = true
                    confirmCautionState = .caution(
                        .init(
                            text: "backup.cloud.password.confirm.error.doesnt_match".localized,
                            type: .error
                        )
                    )
                } else {
                    confirmCautionState = .none
                }
            } catch {
                confirmCautionState = .caution(.init(text: error.localizedDescription, type: .error))
                buttonDisabled = true
            }
        }

        passwordButtonDisabled = buttonDisabled
    }

    @MainActor
    private func showSuccess() {
        HudHelper.instance.show(banner: .savedToCloud)
    }

    @MainActor
    private func show(error: Error) {
        HudHelper.instance.show(banner: .error(string: error.localizedDescription))
    }

    func onTapSave() {
        passwordButtonProcessing = true

        Task {
            switch destination {
            case .none: ()
            case .cloud:
                do {
                    try cloudBackupManager.save(fields: configuration, passphrase: password, name: name)
                    passwordButtonProcessing = false
                    await showSuccess()
                    dismissSubject.send()
                } catch {
                    passwordButtonProcessing = false
                    await show(error: error)
                }
            case .local:
                do {
                    let url = try cloudBackupManager.file(fields: configuration, passphrase: password, name: name)
                    sharePresented = url
                    passwordButtonProcessing = false
                } catch {
                    passwordButtonProcessing = false
                    await show(error: error)
                }
            }
        }
    }
}

extension BackupAppViewModel {
    var dismissPublisher: AnyPublisher<Void, Never> {
        dismissSubject.eraseToAnyPublisher()
    }
}

extension BackupAppViewModel {
    struct AccountItem: Comparable, Identifiable {
        let accountId: String
        let name: String
        let description: String
        let cautionType: CautionType?

        static func < (lhs: AccountItem, rhs: AccountItem) -> Bool {
            lhs.name < rhs.name
        }

        static func == (lhs: AccountItem, rhs: AccountItem) -> Bool {
            lhs.accountId == rhs.accountId
        }

        var id: String {
            accountId
        }
    }

    struct Item: Identifiable {
        let title: String
        let description: String

        var id: String {
            title
        }
    }

    enum NameError: Error, LocalizedError {
        case empty
        case alreadyExist

        var errorDescription: String? {
            switch self {
            case .empty: return "backup.cloud.name.error.empty".localized
            case .alreadyExist: return "backup.cloud.name.error.already_exist".localized
            }
        }
    }
}
