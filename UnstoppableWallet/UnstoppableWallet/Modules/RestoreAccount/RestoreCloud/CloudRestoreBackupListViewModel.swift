import Combine
import Foundation

class CloudRestoreBackupListViewModel: ObservableObject {
    private let service: CloudRestoreBackupService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var walletViewItems: WalletViewItems = .empty
    @Published private(set) var fullBackupViewItems: [BackupViewItem] = []
    private let restoreSubject = PassthroughSubject<BackupModule.NamedSource, Never>()

    init(service: CloudRestoreBackupService) {
        self.service = service

        service.$oneWalletItems
            .sink { [weak self] in self?.sync(items: $0) }
            .store(in: &cancellables)

        service.$fullBackupItems
            .sink { [weak self] in self?.sync(items: $0) }
            .store(in: &cancellables)

        sync(items: service.oneWalletItems)
        sync(items: service.fullBackupItems)
    }

    private func sync(items: [CloudRestoreBackupService.WalletItem]) {
        var imported = [BackupViewItem]()
        var notImported = [BackupViewItem]()

        for item in items {
            let viewItem = viewItem(item: item)
            if item.imported {
                imported.append(viewItem)
            } else {
                notImported.append(viewItem)
            }
        }

        walletViewItems = .init(notImported: notImported, imported: imported)
    }

    private func sync(items: [CloudRestoreBackupService.AppItem]) {
        fullBackupViewItems = items.map { viewItem(item: $0) }
    }

    private func viewItem(item: CloudRestoreBackupService.Item) -> BackupViewItem {
        let description = item.timestamp.map { DateHelper.instance.formatFullTime(from: Date(timeIntervalSince1970: $0)) } ?? "----"
        return BackupViewItem(uniqueId: item.id, name: item.name, description: description)
    }
}

extension CloudRestoreBackupListViewModel {
    var restorePublisher: AnyPublisher<BackupModule.NamedSource, Never> {
        restoreSubject.eraseToAnyPublisher()
    }

    var deleteItemCompletedPublisher: AnyPublisher<Bool, Never> {
        service.deleteItemCompletedPublisher
    }

    func remove(id: String) {
        service.remove(id: id)
    }

    func didTap(id: String) {
        if let item = service.oneWalletItems.first(where: { item in item.id == id }) {
            restoreSubject.send(BackupModule.NamedSource(name: item.name, source: .wallet(item.backup), origin: .cloud))
        }

        if let item = service.fullBackupItems.first(where: { item in item.id == id }) {
            restoreSubject.send(BackupModule.NamedSource(name: item.name, source: .full(item.backup), origin: .cloud))
        }
    }
}

extension CloudRestoreBackupListViewModel {
    enum BackupType {
        case wallet
        case full
    }

    struct BackupViewItem: Hashable {
        let uniqueId: String
        let name: String
        let description: String
    }

    struct WalletViewItems {
        static var empty = WalletViewItems(notImported: [], imported: [])

        let notImported: [BackupViewItem]
        let imported: [BackupViewItem]

        var isEmpty: Bool {
            notImported.isEmpty && imported.isEmpty
        }
    }
}
