import UIKit

class RestoreTypeViewModel {

}

extension RestoreTypeViewModel {
    var items: [RestoreType] { RestoreType.allCases }
}

extension RestoreTypeViewModel {

    enum RestoreType: CaseIterable {
        case cloudRestore
        case recoveryOrPrivateKey
        case watchAddress
    }

}

extension RestoreTypeViewModel.RestoreType {

    var title: String {
        switch self {
        case .cloudRestore: return "restore_type.cloud.title".localized
        case .recoveryOrPrivateKey: return "restore_type.recovery.title".localized
        case .watchAddress: return "restore_type.watch.title".localized
        }
    }

    var description: String {
        switch self {
        case .cloudRestore: return "restore_type.cloud.description".localized
        case .recoveryOrPrivateKey: return "restore_type.recovery.description".localized
        case .watchAddress: return "restore_type.watch.description".localized
        }
    }

    var icon: String {
        switch self {
        case .cloudRestore: return "icloud_24"
        case .recoveryOrPrivateKey: return "edit_24"
        case .watchAddress: return "binocule_24"
        }
    }

}
