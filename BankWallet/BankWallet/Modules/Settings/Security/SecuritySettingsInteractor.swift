import RxSwift

class SecuritySettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ISecuritySettingsInteractorDelegate?

    private let localStorage: ILocalStorage
    private let backupManager: IBackupManager
    private let biometryManager: IBiometryManager
    private let pinManager: IPinManager

    init(localStorage: ILocalStorage, backupManager: IBackupManager, biometryManager: IBiometryManager, pinManager: IPinManager) {
        self.localStorage = localStorage
        self.backupManager = backupManager
        self.biometryManager = biometryManager
        self.pinManager = pinManager

        backupManager.nonBackedUpCountObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] count in
                    self?.delegate?.didUpdateNonBackedUp(count: count)
                })
                .disposed(by: disposeBag)

        pinManager.isPinSetObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] isPinSet in
                    self?.delegate?.didUpdate(isPinSet: isPinSet)
                })
                .disposed(by: disposeBag)

        biometryManager.biometryTypeObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] biometryType in
                    self?.delegate?.didUpdate(biometryType: biometryType)
                })
                .disposed(by: disposeBag)
    }

}

extension SecuritySettingsInteractor: ISecuritySettingsInteractor {

    var nonBackedUpCount: Int {
        return backupManager.nonBackedUpCount
    }

    var biometryType: BiometryType {
        return biometryManager.biometryType
    }

    var isPinSet: Bool {
        return pinManager.isPinSet
    }

    var isBiometricUnlockOn: Bool {
        return localStorage.isBiometricOn
    }

    func disablePin() throws {
        try pinManager.clear()
    }

    func set(biometricUnlockOn: Bool) {
        localStorage.isBiometricOn = biometricUnlockOn
    }

}
