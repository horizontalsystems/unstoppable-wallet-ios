import Foundation
import RxSwift

class GuestInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: IGuestInteractorDelegate?

    private let mnemonic: IMnemonic
    private let loginManager: LoginManager

    init(mnemonic: IMnemonic, loginManager: LoginManager) {
        self.mnemonic = mnemonic
        self.loginManager = loginManager
    }
}

extension GuestInteractor: IGuestInteractor {

    func createWallet() {
        let words = mnemonic.generateWords()

        loginManager.login(withWords: words).subscribeAsync(disposeBag: disposeBag, onError: { [weak self] _ in
            self?.delegate?.didFailToCreateWallet()
        }, onCompleted: { [weak self] in
            self?.delegate?.didCreateWallet()
        })
    }

}
