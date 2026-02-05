import Combine
import Foundation
import LocalAuthentication

class RestoreCloudViewModel {
    private let service: RestoreCloudService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var walletViewItem: ViewItem = .empty
    @Published private(set) var fullBackupViewItem: ViewItem = .empty
    @Published private(set) var processing: Bool = false
    private let restoreSubject = PassthroughSubject<BackupModule.NamedSource, Never>()

    private let openSelectCoinsSubject = PassthroughSubject<RawWalletBackup, Never>()
    private let openConfigurationSubject = PassthroughSubject<RawFullBackup, Never>()
    private let successSubject = PassthroughSubject<Void, Never>()
    private let showErrorSubject = PassthroughSubject<String, Never>()
    private let showLoadingSubject = PassthroughSubject<Bool, Never>()
    private let fallbackToPassphraseSubject = PassthroughSubject<BackupModule.NamedSource, Never>()

    let sourceType: BackupModule.Source.Abstract

    init(service: RestoreCloudService, sourceType: BackupModule.Source.Abstract) {
        self.service = service
        self.sourceType = sourceType

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

    var openSelectCoinsPublisher: AnyPublisher<RawWalletBackup, Never> {
        openSelectCoinsSubject.eraseToAnyPublisher()
    }

    var openConfigurationPublisher: AnyPublisher<RawFullBackup, Never> {
        openConfigurationSubject.eraseToAnyPublisher()
    }

    var successPublisher: AnyPublisher<Void, Never> {
        successSubject.eraseToAnyPublisher()
    }

    var showErrorPublisher: AnyPublisher<String, Never> {
        showErrorSubject.eraseToAnyPublisher()
    }

    var showLoadingPublisher: AnyPublisher<Bool, Never> {
        showLoadingSubject.eraseToAnyPublisher()
    }

    var fallbackToPassphrasePublisher: AnyPublisher<BackupModule.NamedSource, Never> {
        fallbackToPassphraseSubject.eraseToAnyPublisher()
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

        if let item = service.fullBackupItems.first(where: { item in item.source.id == id }) {
            restoreSubject.send(BackupModule.NamedSource(name: item.name, source: item.source))
        }
    }

    func restoreWithBiometry(item: BackupModule.NamedSource) {
        processing = true
        showLoadingSubject.send(true)

        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await service.nextWithBiometricKey(restoredBackup: item)
                processing = false
                showLoadingSubject.send(false)
                handleRestoreResult(result)
            } catch let error as CloudBackupKeyManager.KeyError {
                processing = false
                showLoadingSubject.send(false)
                if let description = error.errorDescription {
                    showErrorSubject.send(description)
                }

                if error == .passphraseNotFound {
                    fallbackToPassphraseSubject.send(item)
                }
            } catch is LAError {
                // User cancelled biometric prompt -- do nothing
                processing = false
                showLoadingSubject.send(false)
            } catch {
                processing = false
                showLoadingSubject.send(false)
                showErrorSubject.send(error.localizedDescription)
            }
        }
    }

    private func handleRestoreResult(_ result: AppBackupProvider.RestoreResult) {
        switch result {
        case let .restoredAccount(rawBackup):
            if rawBackup.enabledWallets.isEmpty {
                openSelectCoinsSubject.send(rawBackup)
            } else {
                successSubject.send()
            }
        case let .restoredFullBackup(rawBackup):
            openConfigurationSubject.send(rawBackup)
        case .success:
            successSubject.send()
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
