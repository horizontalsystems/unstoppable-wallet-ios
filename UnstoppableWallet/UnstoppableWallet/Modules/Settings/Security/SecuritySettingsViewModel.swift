import RxSwift
import RxRelay
import RxCocoa

class SecuritySettingsViewModel {
    private let service: SecuritySettingsService
    private let disposeBag = DisposeBag()

    private let pinViewItemRelay = BehaviorRelay<PinViewItem>(value: PinViewItem(enabled: false, editVisible: false, biometryViewItem: nil))
    private let showErrorRelay = PublishRelay<String>()
    private let openSetPinRelay = PublishRelay<()>()
    private let openUnlockRelay = PublishRelay<()>()

    init(service: SecuritySettingsService) {
        self.service = service

        subscribe(disposeBag, service.pinItemObservable) { [weak self] in self?.sync(pinItem: $0) }

        sync(pinItem: service.pinItem)
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
        case .faceId: return BiometryViewItem(enabled: pinItem.biometryEnabled, icon: "face_id_24", title: "settings_security.face_id".localized)
        case .touchId: return BiometryViewItem(enabled: pinItem.biometryEnabled, icon: "touch_id_2_24", title: "settings_security.touch_id".localized)
        case .none: return nil
        }
    }

}

extension SecuritySettingsViewModel {

    var pinViewItemDriver: Driver<PinViewItem> {
        pinViewItemRelay.asDriver()
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

}
