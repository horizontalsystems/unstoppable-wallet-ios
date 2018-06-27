import Foundation

class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    private let mnemonic: IMnemonic
    private let localStorage: ILocalStorage

    init(mnemonic: IMnemonic, localStorage: ILocalStorage) {
        self.mnemonic = mnemonic
        self.localStorage = localStorage
    }
}

extension GuestInteractor: IGuestInteractor {

    func createWallet() {
        let words = mnemonic.generateWords()

        RealmFactory.instance.login(onCompletion: { [weak self] user, error in
            if let user = user {
                self?.localStorage.save(words: words)
                self?.delegate?.didCreateWallet()
            } else if let error = error {
//                self?.delegate?.didCreateWallet()
            }
        })
    }

}
