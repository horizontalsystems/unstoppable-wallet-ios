import RxSwift
import RxRelay
import PinKit

class SecurityService {
    private let pinKit: IPinKit
    private let disposeBag = DisposeBag()

    private let pinItemRelay = PublishRelay<PinItem>()
    private(set) var pinItem: PinItem = PinItem(enabled: false, biometryEnabled: false, biometryType: nil) {
        didSet {
            pinItemRelay.accept(pinItem)
        }
    }

    init(pinKit: IPinKit) {
        self.pinKit = pinKit

        subscribe(disposeBag, pinKit.isPinSetObservable) { [weak self] _ in self?.syncPinItem() }
        subscribe(disposeBag, pinKit.biometryTypeObservable) { [weak self] _ in self?.syncPinItem() }

        syncPinItem()
    }

    private func syncPinItem() {
        pinItem = PinItem(enabled: pinKit.isPinSet, biometryEnabled: pinKit.biometryEnabled, biometryType: pinKit.biometryType)
    }

}

extension SecurityService {

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

extension SecurityService {

    struct PinItem {
        let enabled: Bool
        let biometryEnabled: Bool
        let biometryType: BiometryType?
    }

}
