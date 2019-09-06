import RxSwift

class SecuritySettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ISecuritySettingsInteractorDelegate?

    private let backupManager: IBackupManager
    private let biometryManager: IBiometryManager
    private let pinManager: IPinManager

    init(backupManager: IBackupManager, biometryManager: IBiometryManager, pinManager: IPinManager) {
        self.backupManager = backupManager
        self.biometryManager = biometryManager
        self.pinManager = pinManager

        backupManager.allBackedUpObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] allBackedUp in
                    self?.delegate?.didUpdate(allBackedUp: allBackedUp)
                })
                .disposed(by: disposeBag)

        pinManager.isPinSetObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] isPinSet in
                    self?.delegate?.didUpdate(pinSet: isPinSet)
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

    var allBackedUp: Bool {
        return backupManager.allBackedUp
    }

    var biometryType: BiometryType {
        return biometryManager.biometryType
    }

    var pinSet: Bool {
        return pinManager.isPinSet
    }

    var biometryEnabled: Bool {
        get {
            return pinManager.biometryEnabled
        }
        set {
            pinManager.biometryEnabled = newValue
        }
    }

    func disablePin() throws {
        try pinManager.clear()
    }

}
