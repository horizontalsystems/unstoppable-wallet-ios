import Combine
import Foundation

class RestoreBackupListViewModel: ObservableObject {
    private let service = CloudRestoreBackupService()
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var viewItems: [BackupViewItem] = []
    private let restoreSubject = PassthroughSubject<BackupModule.NamedSource, Never>()

    init() {
        service.$oneWalletItems
            .combineLatest(service.$fullBackupItems)
            .sink { [weak self] wallets, fullBackups in
                self?.sync(walletItems: wallets, fullBackupItems: fullBackups)
            }
            .store(in: &cancellables)

        sync(walletItems: service.oneWalletItems, fullBackupItems: service.fullBackupItems)
    }

    private func sync(walletItems: [CloudRestoreBackupService.WalletItem], fullBackupItems: [CloudRestoreBackupService.AppItem]) {
        let wallets = walletItems.map { viewItem(item: $0, walletCount: nil) }
        let fulls = fullBackupItems.map { viewItem(item: $0, walletCount: $0.backup.wallets.count) }

        viewItems = (wallets + fulls).sorted { ($0.timestamp ?? 0) > ($1.timestamp ?? 0) }
    }

    private func viewItem(item: CloudRestoreBackupService.Item, walletCount: Int?) -> BackupViewItem {
        let description = item.timestamp.map { DateHelper.instance.formatFullTime(from: Date(timeIntervalSince1970: $0)) } ?? "----"
        return BackupViewItem(uniqueId: item.id, name: item.name, description: description, walletCount: walletCount, timestamp: item.timestamp)
    }
}

extension RestoreBackupListViewModel {
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

extension RestoreBackupListViewModel {
    struct BackupViewItem: Hashable {
        let uniqueId: String
        let name: String
        let description: String
        let walletCount: Int?
        let timestamp: TimeInterval?

        var isFull: Bool { walletCount != nil }
    }
}
