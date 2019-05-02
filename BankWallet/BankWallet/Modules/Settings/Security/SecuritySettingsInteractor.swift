import RxSwift

class SecuritySettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ISecuritySettingsInteractorDelegate?

    private let localStorage: ILocalStorage
    private let wordsManager: IWordsManager
    private let systemInfoManager: ISystemInfoManager
    private let async: Bool

    init(localStorage: ILocalStorage, wordsManager: IWordsManager, systemInfoManager: ISystemInfoManager, async: Bool = true) {
        self.localStorage = localStorage
        self.wordsManager = wordsManager
        self.systemInfoManager = systemInfoManager
        self.async = async

        wordsManager.backedUpSignal
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateBackedUp()
                })
                .disposed(by: disposeBag)
    }

    private func onUpdateBackedUp() {
        if wordsManager.isBackedUp {
            delegate?.didBackup()
        }
    }

}

extension SecuritySettingsInteractor: ISecuritySettingsInteractor {

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

    var isBackedUp: Bool {
        return wordsManager.isBackedUp
    }

    func set(biometricUnlockOn: Bool) {
        localStorage.isBiometricOn = biometricUnlockOn
    }

}
