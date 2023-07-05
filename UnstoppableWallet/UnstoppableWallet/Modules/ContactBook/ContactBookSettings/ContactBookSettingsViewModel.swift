import Foundation
import RxRelay
import RxSwift
import RxCocoa

class ContactBookSettingsViewModel {
    private let disposeBag = DisposeBag()
    private let service: ContactBookSettingsService

    private let featureEnabledRelay = BehaviorRelay<Bool>(value: false)

    private let showConfirmationRelay = PublishRelay<()>()
    private let showSyncErrorRelay = PublishRelay<Bool>()

    private let showRestoreAlertRelay = PublishRelay<[BackupContact]>()
    private let showParsingErrorRelay = PublishRelay<()>()
    private let showSuccessfulRestoreRelay = PublishRelay<()>()
    private let showRestoreErrorRelay = PublishRelay<()>()

    init(service: ContactBookSettingsService) {
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
extension ContactBookSettingsViewModel {

    var showRestoreAlertSignal: Signal<[BackupContact]> {
        showRestoreAlertRelay.asSignal()
    }

    var showParsingErrorSignal: Signal<()> {
        showParsingErrorRelay.asSignal()
    }

    var showSuccessfulRestoreSignal: Signal<()> {
        showSuccessfulRestoreRelay.asSignal()
    }

    var showRestoreErrorSignal: Signal<()> {
        showRestoreErrorRelay.asSignal()
    }

    var hasContacts: Bool {
        service.hasContacts
    }

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

    func didPick(url: URL) {
        do {
            let backupContacts = try service.backupContacts(from: url)
            showRestoreAlertRelay.accept(backupContacts)
        } catch {
            showParsingErrorRelay.accept(())
        }
    }

    func replace(contacts: [BackupContact]) {
        do {
            try service.replace(contacts: contacts)
            showSuccessfulRestoreRelay.accept(())
        } catch {
            showRestoreErrorRelay.accept(())
        }
    }

    func createBackupFile() throws -> URL {
        try service.createBackupFile()
    }

}
