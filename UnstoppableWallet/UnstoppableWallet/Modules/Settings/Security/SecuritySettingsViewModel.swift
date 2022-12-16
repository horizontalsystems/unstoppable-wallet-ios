import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class SecuritySettingsViewModel {
    private let service: SecuritySettingsService
    private let disposeBag = DisposeBag()

    private let pinViewItemRelay = BehaviorRelay<PinViewItem>(value: PinViewItem(enabled: false, editVisible: false, biometryViewItem: nil))
    private let blockchainViewItemsRelay = BehaviorRelay<[BlockchainViewItem]>(value: [])
    private let showErrorRelay = PublishRelay<String>()
    private let openSetPinRelay = PublishRelay<()>()
    private let openUnlockRelay = PublishRelay<()>()
    private let openBtcBlockchainRelay = PublishRelay<Blockchain>()
    private let openEvmBlockchainRelay = PublishRelay<Blockchain>()

    init(service: SecuritySettingsService) {
        self.service = service

        subscribe(disposeBag, service.pinItemObservable) { [weak self] in self?.sync(pinItem: $0) }
        subscribe(disposeBag, service.blockchainItemsObservable) { [weak self] in self?.sync(blockchainItems: $0) }

        sync(pinItem: service.pinItem)
        sync(blockchainItems: service.blockchainItems)
    }

    private func sync(pinItem: SecuritySettingsService.PinItem) {
        let viewItem = PinViewItem(
                enabled: pinItem.enabled,
                editVisible: pinItem.enabled,
                biometryViewItem: biometryViewItem(pinItem: pinItem)
        )

        pinViewItemRelay.accept(viewItem)
    }

    private func biometryViewItem(pinItem: SecuritySettingsService.PinItem) -> BiometryViewItem? {
        guard pinItem.enabled else {
            return nil
        }

        guard let biometryType = pinItem.biometryType else {
            return nil
        }

        switch biometryType {
        case .faceId: return BiometryViewItem(enabled: pinItem.biometryEnabled, icon: "face_id_20", title: "settings_security.face_id".localized)
        case .touchId: return BiometryViewItem(enabled: pinItem.biometryEnabled, icon: "touch_id_2_20", title: "settings_security.touch_id".localized)
        case .none: return nil
        }
    }

    private func sync(blockchainItems: [SecuritySettingsService.BlockchainItem]) {
        let viewItems = blockchainItems.map { item -> BlockchainViewItem in
            switch item {
            case .btc(let blockchain, let restoreMode, let transactionMode):
                return BlockchainViewItem(
                        iconUrl: blockchain.type.imageUrl,
                        name: blockchain.name,
                        value: "\(restoreMode.title), \(transactionMode.title)"
                )
            case .evm(let blockchain, let syncSource):
                return BlockchainViewItem(
                        iconUrl: blockchain.type.imageUrl,
                        name: blockchain.name,
                        value: syncSource.name
                )
            }
        }

        blockchainViewItemsRelay.accept(viewItems)
    }

}

extension SecuritySettingsViewModel {

    var pinViewItemDriver: Driver<PinViewItem> {
        pinViewItemRelay.asDriver()
    }

    var blockchainViewItemsDriver: Driver<[BlockchainViewItem]> {
        blockchainViewItemsRelay.asDriver()
    }

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
    }

    var openSetPinSignal: Signal<()> {
        openSetPinRelay.asSignal()
    }

    var openUnlockSignal: Signal<()> {
        openUnlockRelay.asSignal()
    }

    var openBtcBlockchainSignal: Signal<Blockchain> {
        openBtcBlockchainRelay.asSignal()
    }

    var openEvmBlockchainSignal: Signal<Blockchain> {
        openEvmBlockchainRelay.asSignal()
    }

    func onTogglePin(isOn: Bool) {
        if service.pinItem.enabled {
            openUnlockRelay.accept(())
        } else {
            openSetPinRelay.accept(())
        }
    }

    func onToggleBiometry(isOn: Bool) {
        service.toggleBiometry(isOn: isOn)
    }

    func onUnlock() -> Bool {
        do {
            try service.disablePin()
            return true
        } catch {
            showErrorRelay.accept(error.smartDescription)
            return false
        }
    }

    func onTapBlockchain(index: Int) {
        let item = service.blockchainItems[index]

        switch item {
        case .btc(let blockchain, _, _):
            openBtcBlockchainRelay.accept(blockchain)
        case .evm(let blockchain, _):
            openEvmBlockchainRelay.accept(blockchain)
        }
    }

}

extension SecuritySettingsViewModel {

    struct PinViewItem {
        let enabled: Bool
        let editVisible: Bool
        let biometryViewItem: BiometryViewItem?
    }

    struct BiometryViewItem {
        let enabled: Bool
        let icon: String
        let title: String
    }

    struct BlockchainViewItem {
        let iconUrl: String
        let name: String
        let value: String
    }

}
