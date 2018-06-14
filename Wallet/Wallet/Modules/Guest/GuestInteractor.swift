import Foundation

class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    let mnemonic: MnemonicProtocol
    let localStorage: LocalStorageProtocol

    init(mnemonic: MnemonicProtocol, localStorage: LocalStorageProtocol) {
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
