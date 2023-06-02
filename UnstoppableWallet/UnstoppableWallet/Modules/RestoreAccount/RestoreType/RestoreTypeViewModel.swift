import UIKit
import Combine

class RestoreTypeViewModel {
    private let cloudAccountBackupManager: CloudAccountBackupManager

    private let showCloudNotAvailableSubject = PassthroughSubject<Void, Never>()
    private let showModuleSubject = PassthroughSubject<RestoreType, Never>()

    init(cloudAccountBackupManager: CloudAccountBackupManager) {
        self.cloudAccountBackupManager = cloudAccountBackupManager
    }

}

extension RestoreTypeViewModel {

    var items: [RestoreType] { RestoreType.allCases }

    var showCloudNotAvailablePublisher: AnyPublisher<Void, Never> {
        showCloudNotAvailableSubject.eraseToAnyPublisher()
    }

    var showModulePublisher: AnyPublisher<RestoreType, Never> {
        showModuleSubject.eraseToAnyPublisher()
    }

    func onTap(type: RestoreType) {
        switch type {
        case .recoveryOrPrivateKey: showModuleSubject.send(type)
        case .cloudRestore:
            if cloudAccountBackupManager.isAvailable {
                showModuleSubject.send(type)
            } else {
                showCloudNotAvailableSubject.send(())
            }
        }
    }

}

extension RestoreTypeViewModel {

    enum RestoreType: CaseIterable {
        case recoveryOrPrivateKey
        case cloudRestore
    }

}

extension RestoreTypeViewModel.RestoreType {

    var title: String {
        switch self {
        case .cloudRestore: return "restore_type.cloud.title".localized
        case .recoveryOrPrivateKey: return "restore_type.recovery.title".localized
        }
    }

    var description: String {
        switch self {
        case .cloudRestore: return "restore_type.cloud.description".localized
        case .recoveryOrPrivateKey: return "restore_type.recovery.description".localized
        }
    }

    var icon: String {
        switch self {
        case .cloudRestore: return "icloud_24"
        case .recoveryOrPrivateKey: return "edit_24"
        }
    }

}
