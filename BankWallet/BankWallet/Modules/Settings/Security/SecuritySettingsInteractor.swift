import RxSwift
import PinKit

class SecuritySettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ISecuritySettingsInteractorDelegate?

    private let backupManager: IBackupManager
    private let biometryManager: IBiometryManager
    private let pinKit: IPinKit

    init(backupManager: IBackupManager, biometryManager: IBiometryManager, pinKit: IPinKit) {
        self.backupManager = backupManager
        self.biometryManager = biometryManager
        self.pinKit = pinKit

        backupManager.allBackedUpObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] allBackedUp in
                    self?.delegate?.didUpdate(allBackedUp: allBackedUp)
                })
                .disposed(by: disposeBag)

        pinKit.isPinSetObservable
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
        backupManager.allBackedUp
    }

    var biometryType: BiometryType {
        biometryManager.biometryType
    }

    var pinSet: Bool {
        pinKit.isPinSet
    }

    var biometryEnabled: Bool {
        get {
            pinKit.biometryEnabled
        }
        set {
            pinKit.biometryEnabled = newValue
        }
    }

    func disablePin() throws {
        try pinKit.clear()
    }

}
