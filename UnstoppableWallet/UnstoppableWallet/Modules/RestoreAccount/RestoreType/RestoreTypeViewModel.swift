import Combine
import UIKit

class RestoreTypeViewModel {
    private let cloudAccountBackupManager: CloudBackupManager
    let sourceType: BackupModule.Source.Abstract

    private let showCloudNotAvailableSubject = PassthroughSubject<Void, Never>()
    private let showWrongFileSubject = PassthroughSubject<Void, Never>()
    private let showModuleSubject = PassthroughSubject<RestoreTypeModule.RestoreType, Never>()
    private let showRestoreBackupSubject = PassthroughSubject<BackupModule.NamedSource, Never>()

    init(cloudAccountBackupManager: CloudBackupManager, sourceType: BackupModule.Source.Abstract) {
        self.cloudAccountBackupManager = cloudAccountBackupManager
        self.sourceType = sourceType
    }
}

extension RestoreTypeViewModel {
    var showCloudNotAvailablePublisher: AnyPublisher<Void, Never> {
        showCloudNotAvailableSubject.eraseToAnyPublisher()
    }

    var showWrongFilePublisher: AnyPublisher<Void, Never> {
        showWrongFileSubject.eraseToAnyPublisher()
    }

    var showModulePublisher: AnyPublisher<RestoreTypeModule.RestoreType, Never> {
        showModuleSubject.eraseToAnyPublisher()
    }

    var showRestoreBackupPublisher: AnyPublisher<BackupModule.NamedSource, Never> {
        showRestoreBackupSubject.eraseToAnyPublisher()
    }

    func onTap(type: RestoreTypeModule.RestoreType) {
        switch type {
        case .recoveryOrPrivateKey, .cex, .fileRestore: showModuleSubject.send(type)
        case .cloudRestore:
            if cloudAccountBackupManager.isAvailable {
                showModuleSubject.send(type)
            } else {
                showCloudNotAvailableSubject.send(())
            }
        }
    }

    func didPick(url: URL) {
        do {
            let namedSource = try RestoreFileHelper.parse(url: url)
            showRestoreBackupSubject.send(namedSource)
        } catch {
            showWrongFileSubject.send()
        }
    }
}

extension RestoreTypeViewModel {
    var items: [RestoreTypeModule.RestoreType] {
        switch sourceType {
        case .wallet: return [.recoveryOrPrivateKey, .cloudRestore, .fileRestore, .cex]
        case .full: return [.cloudRestore, .fileRestore]
        }
    }

    var title: String {
        switch sourceType {
        case .wallet: return "restore.title".localized
        case .full: return "backup_app.restore_type.title".localized
        }
    }

    func title(type: RestoreTypeModule.RestoreType) -> String {
        switch type {
        case .recoveryOrPrivateKey: return "restore_type.recovery.title".localized
        case .cloudRestore: return "restore_type.cloud.title".localized
        case .fileRestore: return "restore_type.file.title".localized
        case .cex: return "restore_type.cex.title".localized
        }
    }

    func description(type: RestoreTypeModule.RestoreType) -> String {
        switch type {
        case .recoveryOrPrivateKey: return "restore_type.recovery.description".localized
        case .cloudRestore: return "restore_type.cloud.description".localized
        case .fileRestore: return "restore_type.file.description".localized
        case .cex: return "restore_type.cex.description".localized
        }
    }

    func icon(type: RestoreTypeModule.RestoreType) -> String {
        switch type {
        case .recoveryOrPrivateKey: return "edit_24"
        case .cloudRestore: return "icloud_24"
        case .fileRestore: return "file_24"
        case .cex: return "link_24"
        }
    }
}
