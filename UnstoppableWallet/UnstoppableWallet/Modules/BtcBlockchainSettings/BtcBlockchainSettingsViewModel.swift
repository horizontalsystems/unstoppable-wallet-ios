import Combine

class BtcBlockchainSettingsViewModel: ObservableObject {
    private let service: BtcBlockchainSettingsService

    let restoreModes: [BtcRestoreMode] = BtcRestoreMode.allCases

    @Published var selectedRestoreMode: BtcRestoreMode {
        didSet {
            saveEnabled = selectedRestoreMode != service.currentRestoreMode
        }
    }

    @Published var saveEnabled = false

    init(service: BtcBlockchainSettingsService) {
        self.service = service

        selectedRestoreMode = service.currentRestoreMode
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
