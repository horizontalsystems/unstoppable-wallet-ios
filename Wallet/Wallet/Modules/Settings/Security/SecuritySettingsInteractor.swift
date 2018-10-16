import Foundation
import RxSwift

class SecuritySettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ISecuritySettingsInteractorDelegate?

    private let localStorage: ILocalStorage
    private let wordsManager: IWordsManager

    init(localStorage: ILocalStorage, wordsManager: IWordsManager) {
        self.localStorage = localStorage
        self.wordsManager = wordsManager

        wordsManager.backedUpSubject
                .subscribe(onNext: { [weak self] isBackedUp in
                    self?.onUpdate(isBackedUp: isBackedUp)
                })
                .disposed(by: disposeBag)
    }

    private func onUpdate(isBackedUp: Bool) {
        if isBackedUp {
            delegate?.didBackup()
        }
    }

}

extension SecuritySettingsInteractor: ISecuritySettingsInteractor {

    var isBiometricUnlockOn: Bool {
        return localStorage.isBiometricOn
    }

    var isBackedUp: Bool {
        return wordsManager.isBackedUp
    }

    func set(biometricUnlockOn: Bool) {
        localStorage.isBiometricOn = biometricUnlockOn
    }

}
