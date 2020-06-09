import RxSwift
import PinKit

class SecuritySettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ISecuritySettingsInteractorDelegate?

    private let backupManager: IBackupManager
    private let pinKit: IPinKit

    init(backupManager: IBackupManager, pinKit: IPinKit) {
        self.backupManager = backupManager
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

        pinKit.biometryTypeObservable
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

    var biometryType: BiometryType? {
        pinKit.biometryType
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
