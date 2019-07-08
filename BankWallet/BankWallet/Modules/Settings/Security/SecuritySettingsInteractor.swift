import RxSwift

class SecuritySettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ISecuritySettingsInteractorDelegate?

    private let localStorage: ILocalStorage
    private let accountManager: IAccountManager
    private let systemInfoManager: ISystemInfoManager
    private let async: Bool

    init(localStorage: ILocalStorage, accountManager: IAccountManager, systemInfoManager: ISystemInfoManager, async: Bool = true) {
        self.localStorage = localStorage
        self.accountManager = accountManager
        self.systemInfoManager = systemInfoManager
        self.async = async

        accountManager.nonBackedUpCountObservable
                .subscribe(onNext: { [weak self] count in
                    self?.delegate?.didUpdateNonBackedUp(count: count)
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

    func getBiometryType() {
        var single = systemInfoManager.biometryType
            if async {
                single = single
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                        .observeOn(MainScheduler.instance)
            }
            single.subscribe(onSuccess: { [weak self] type in
                self?.delegate?.didGetBiometry(type: type)
            }).disposed(by: disposeBag)
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
