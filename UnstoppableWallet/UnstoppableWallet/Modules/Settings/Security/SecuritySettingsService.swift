import Combine
import RxSwift
import RxRelay
import PinKit

class SecuritySettingsService {
    private let pinKit: PinKit.Kit
    private var cancellables = Set<AnyCancellable>()

    private let pinItemRelay = PublishRelay<PinItem>()
    private(set) var pinItem: PinItem = PinItem(enabled: false, biometryEnabled: false, biometryType: nil) {
        didSet {
            pinItemRelay.accept(pinItem)
        }
    }

    init(pinKit: PinKit.Kit) {
        self.pinKit = pinKit

        pinKit.isPinSetPublisher
                .sink { [weak self] _ in self?.syncPinItem() }
                .store(in: &cancellables)

        pinKit.biometryTypePublisher
                .sink { [weak self] _ in self?.syncPinItem() }
                .store(in: &cancellables)

        syncPinItem()
    }

    private func syncPinItem() {
        pinItem = PinItem(enabled: pinKit.isPinSet, biometryEnabled: pinKit.biometryEnabled, biometryType: pinKit.biometryType)
    }

}

extension SecuritySettingsService {

    var pinItemObservable: Observable<PinItem> {
        pinItemRelay.asObservable()
    }

    func toggleBiometry(isOn: Bool) {
        pinKit.biometryEnabled = isOn
    }

    func disablePin() throws {
        try pinKit.clear()
    }

}

extension SecuritySettingsService {

    struct PinItem {
        let enabled: Bool
        let biometryEnabled: Bool
        let biometryType: BiometryType?
    }

}
