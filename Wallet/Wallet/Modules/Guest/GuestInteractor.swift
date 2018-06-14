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
        localStorage.save(words: mnemonic.generateWords())
        delegate?.didCreateWallet()
    }

}
