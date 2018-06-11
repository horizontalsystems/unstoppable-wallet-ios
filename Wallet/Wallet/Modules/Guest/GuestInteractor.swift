import Foundation

class GuestInteractor {
    weak var presenter: GuestPresenterProtocol?

    let mnemonic: MnemonicProtocol
    let localStorage: LocalStorageProtocol

    init(mnemonic: MnemonicProtocol, localStorage: LocalStorageProtocol) {
        self.mnemonic = mnemonic
        self.localStorage = localStorage
    }
}

extension GuestInteractor: GuestPresenterDelegate {

    func createWallet() {
        localStorage.save(words: mnemonic.generateWords())
        presenter?.didCreateWallet()
    }

}
