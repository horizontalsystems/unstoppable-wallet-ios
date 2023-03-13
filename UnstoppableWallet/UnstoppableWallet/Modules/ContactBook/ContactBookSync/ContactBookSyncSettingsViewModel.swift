import RxRelay
import RxSwift
import RxCocoa

class ContactBookSyncSettingsViewModel {
    private let disposeBag = DisposeBag()
    private let service: ContactBookSyncSettingsService

    private let featureEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let showConfirmationRelay = PublishRelay<()>()

    init(service: ContactBookSyncSettingsService) {
        self.service = service

        subscribe(disposeBag, service.activatedChangedObservable) { [weak self] in self?.sync(featureEnabled: $0) }
        subscribe(disposeBag, service.confirmationObservable) { [weak self] in self?.showConfirmationRelay.accept(()) }
    }

    private func sync(featureEnabled: Bool) {
        featureEnabledRelay.accept(featureEnabled)
    }

}
extension ContactBookSyncSettingsViewModel {

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
