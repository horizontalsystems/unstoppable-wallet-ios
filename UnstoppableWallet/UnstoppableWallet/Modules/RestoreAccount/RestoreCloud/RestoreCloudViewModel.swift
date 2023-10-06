import Foundation
import Combine

class RestoreCloudViewModel {
    private let service: RestoreCloudService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var walletViewItem: ViewItem = .empty
    @Published private(set) var fullBackupViewItem: ViewItem = .empty
    private let restoreSubject = PassthroughSubject<BackupModule.NamedSource, Never>()

    init(service: RestoreCloudService) {
        self.service = service

        service.$oneWalletItems
                .sink { [weak self] in self?.sync(type: .wallet, items: $0) }
                .store(in: &cancellables)

        service.$fullBackupItems
                .sink { [weak self] in self?.sync(type: .full, items: $0) }
                .store(in: &cancellables)

        sync(type: .wallet, items: service.oneWalletItems)
        sync(type: .full, items: service.fullBackupItems)
    }

    private func sync(type: BackupModule.Source.Abstract, items: [RestoreCloudService.Item]) {
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

        switch type {
        case .wallet: walletViewItem = ViewItem(notImported: notImported, imported: imported)
        case .full: fullBackupViewItem = ViewItem(notImported: notImported, imported: imported)
        }
    }

    private func viewItem(item: RestoreCloudService.Item) -> BackupViewItem {
        let description = item.source.timestamp.map { DateHelper.instance.formatFullTime(from: Date(timeIntervalSince1970: $0)) } ?? "----"
        return BackupViewItem(uniqueId: item.source.id, name: item.name, description: description)
    }

}

extension RestoreCloudViewModel {

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
        if let item = service.oneWalletItems.first(where: { item in item.source.id == id }) {
            restoreSubject.send(BackupModule.NamedSource(name: item.name, source: item.source))
        }

        if let item = service.fullBackupItems.first(where: { item in item.source.id == id}) {
            restoreSubject.send(BackupModule.NamedSource(name: item.name, source: item.source))
        }
    }

}

extension RestoreCloudViewModel {
    enum BackupType {
        case wallet
        case full
    }

    struct BackupViewItem {
        let uniqueId: String
        let name: String
        let description: String
    }

    struct ViewItem {
        static var empty = ViewItem(notImported: [], imported: [])

        let notImported: [BackupViewItem]
        let imported: [BackupViewItem]

        var isEmpty: Bool {
            notImported.isEmpty && imported.isEmpty
        }
    }

}
