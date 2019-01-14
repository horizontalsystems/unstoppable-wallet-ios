import RxSwift

class SecuritySettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ISecuritySettingsInteractorDelegate?

    private let localStorage: ILocalStorage
    private let authManager: IAuthManager
    private let wordsManager: IWordsManager
    private let systemInfoManager: ISystemInfoManager

    init(localStorage: ILocalStorage, authManager: IAuthManager, wordsManager: IWordsManager, systemInfoManager: ISystemInfoManager) {
        self.localStorage = localStorage
        self.authManager = authManager
        self.wordsManager = wordsManager
        self.systemInfoManager = systemInfoManager

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

    var biometryType: BiometryType {
        return systemInfoManager.biometryType
    }

    var isBackedUp: Bool {
        return wordsManager.isBackedUp
    }

    func set(biometricUnlockOn: Bool) {
        localStorage.isBiometricOn = biometricUnlockOn
    }

    func unlink() {
        do {
            try authManager.logout()
            delegate?.didUnlink()
        } catch {
            // todo
        }
    }

}
