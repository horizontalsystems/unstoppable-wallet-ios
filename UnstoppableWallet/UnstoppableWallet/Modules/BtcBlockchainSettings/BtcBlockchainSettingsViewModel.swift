import Combine

class BtcBlockchainSettingsViewModel: ObservableObject {
    private let service: BtcBlockchainSettingsService

    let restoreModes: [BtcRestoreModeViewItem]

    @Published var selectedRestoreMode: BtcRestoreMode {
        didSet {
            saveEnabled = selectedRestoreMode != service.currentRestoreMode
        }
    }

    @Published var saveEnabled = false

    init(service: BtcBlockchainSettingsService) {
        self.service = service

        selectedRestoreMode = service.currentRestoreMode
        restoreModes = service.restoreModes.map { restoreMode in
            let image: BtcRestoreModeViewItem.Image
            switch restoreMode.restoreMode {
            case .blockchair:
                image = .local(name: "blockchair_32")
            case .hybrid:
                image = .local(name: "api_placeholder_32")
            case .blockchain:
                image = .remote(url: service.blockchain.type.imageUrl)
            }

            let description: String
            switch restoreMode.restoreMode {
            case .blockchair: description = "btc_restore_mode.blockchair".localized
            case .hybrid: description = "btc_restore_mode.hybrid".localized
            case .blockchain: description = "btc_restore_mode.blockchain".localized
            }

            return BtcRestoreModeViewItem(
                restoreMode: restoreMode.restoreMode,
                title: restoreMode.title,
                description: description,
                icon: image
            )
        }
    }
}

extension BtcBlockchainSettingsViewModel {
    var title: String {
        service.blockchain.name
    }

    var iconUrl: String {
        service.blockchain.type.imageUrl
    }

    func onTapSave() {
        service.save(restoreMode: selectedRestoreMode)
    }
}

struct BtcRestoreModeViewItem {
    let restoreMode: BtcRestoreMode
    let title: String
    let description: String
    let icon: Image

    enum Image {
        case local(name: String)
        case remote(url: String)
    }
}
