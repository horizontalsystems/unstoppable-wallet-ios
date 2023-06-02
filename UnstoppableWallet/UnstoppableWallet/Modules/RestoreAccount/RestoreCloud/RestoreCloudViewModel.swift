import Foundation
import Combine

class RestoreCloudViewModel {
    private let service: RestoreCloudService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var viewItem: ViewItem = .empty
    private let restoreSubject = PassthroughSubject<RestoreCloudModule.RestoredBackup, Never>()

    init(service: RestoreCloudService) {
        self.service = service

        service.$items
                .sink { [weak self] in self?.sync(items: $0) }
                .store(in: &cancellables)

        sync(items: service.items)
    }

    private func sync(items: [RestoreCloudService.Item]) {
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

        viewItem = ViewItem(notImported: notImported, imported: imported)
    }

    private func viewItem(item: RestoreCloudService.Item) -> BackupViewItem {
        let description = item.backup.timestamp.map { DateHelper.instance.formatFullTime(from: Date(timeIntervalSince1970: $0)) } ?? "----"
        return BackupViewItem(uniqueId: item.backup.id, name: item.name, description: description)
    }

}

extension RestoreCloudViewModel {

    var restorePublisher: AnyPublisher<RestoreCloudModule.RestoredBackup, Never> {
        restoreSubject.eraseToAnyPublisher()
    }

    func didTap(id: String) {
        guard let item = service.items.first(where: { item in item.backup.id == id }) else {
            return
        }

        restoreSubject.send(RestoreCloudModule.RestoredBackup(name: item.name, walletBackup: item.backup))
    }

}

extension RestoreCloudViewModel {

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
