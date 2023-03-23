import RxRelay
import RxSwift
import RxCocoa

class ContactBookSyncSettingsViewModel {
    private let disposeBag = DisposeBag()
    private let service: ContactBookSyncSettingsService

    private let featureEnabledRelay = BehaviorRelay<Bool>(value: false)

    private let showConfirmationRelay = PublishRelay<()>()
    private let showSyncErrorRelay = PublishRelay<Bool>()

    init(service: ContactBookSyncSettingsService) {
        self.service = service

        subscribe(disposeBag, service.activatedChangedObservable) { [weak self] in self?.sync(featureEnabled: $0) }
        subscribe(disposeBag, service.cloudErrorObservable) { [weak self] in self?.sync(error: $0) }
        subscribe(disposeBag, service.confirmationObservable) { [weak self] in self?.showConfirmationRelay.accept(()) }
    }

    private func sync(featureEnabled: Bool) {
        featureEnabledRelay.accept(featureEnabled)
    }

    private func sync(error: Error?, activatedOnly: Bool = false) {
        guard let error else {
            return
        }

        if activatedOnly, !service.activated {  // don't show alert on start (activated only shows)
            return
        }

        if case .cloudUrlNotAvailable = error as? ContactBookManager.StorageError {
            showSyncErrorRelay.accept(service.activated)
        }
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

    var showSyncErrorSignal: Signal<Bool> {
        showSyncErrorRelay.asSignal()
    }

    func onViewAppeared() {
        // if sync is On, but no access to iCloud folder we need show alert
        sync(error: service.cloudError, activatedOnly: true)
    }

    func onToggle(isOn: Bool) {
        service.toggle(isOn: isOn)
    }

    func onConfirm() {
        service.confirm()
    }

}
