import RxSwift

class SecuritySettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ISecuritySettingsInteractorDelegate?

    private let localStorage: ILocalStorage
    private let accountManager: IAccountManager
    private let systemInfoManager: ISystemInfoManager
    private let pinManager: IPinManager

    init(localStorage: ILocalStorage, accountManager: IAccountManager, systemInfoManager: ISystemInfoManager, pinManager: IPinManager) {
        self.localStorage = localStorage
        self.accountManager = accountManager
        self.systemInfoManager = systemInfoManager
        self.pinManager = pinManager

        accountManager.nonBackedUpCountObservable
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
    }

}

extension SecuritySettingsInteractor: ISecuritySettingsInteractor {

    var nonBackedUpCount: Int {
        return accountManager.nonBackedUpCount
    }

    var isBiometricUnlockOn: Bool {
        return localStorage.isBiometricOn
    }

    var isPinSet: Bool {
        return pinManager.isPinSet
    }

    func getBiometryType() {
        systemInfoManager.biometryType
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] type in
                    self?.delegate?.didGetBiometry(type: type)
                })
                .disposed(by: disposeBag)
    }

    func set(biometricUnlockOn: Bool) {
        localStorage.isBiometricOn = biometricUnlockOn
    }

}

extension SecuritySettingsInteractor: IUnlockDelegate {

    func onUnlock() {
        delegate?.onUnlock()
    }

    func onCancelUnlock() {
        delegate?.onCancelUnlock()
    }

}
