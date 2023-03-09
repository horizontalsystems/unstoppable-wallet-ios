import RxRelay
import RxSwift
import RxCocoa

class AddressBookSyncSettingsViewModel {
    private let disposeBag = DisposeBag()
    private let service: AddressBookSyncSettingsService

    private let featureEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let showConfirmationRelay = PublishRelay<()>()

    init(service: AddressBookSyncSettingsService) {
        self.service = service

        subscribe(disposeBag, service.activatedChangedObservable) { [weak self] in self?.sync(featureEnabled: $0) }
        subscribe(disposeBag, service.confirmationObservable) { [weak self] in self?.showConfirmationRelay.accept(()) }
    }

    private func sync(featureEnabled: Bool) {
        featureEnabledRelay.accept(featureEnabled)
    }

}
extension AddressBookSyncSettingsViewModel {

    var featureEnabled: Bool {
        service.activated
    }

    var featureEnabledDriver: Driver<Bool> {
        featureEnabledRelay.asDriver()
    }

    var showConfirmationSignal: Signal<()> {
        showConfirmationRelay.asSignal()
    }

    func onToggle() {
        service.toggle()
    }

    func onConfirm() {
        service.confirm()
    }

}
