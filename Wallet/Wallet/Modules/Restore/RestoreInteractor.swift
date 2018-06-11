import Foundation

class RestoreInteractor {
    weak var presenter: RestorePresenterProtocol?

    let mnemonic: MnemonicProtocol
    let localStorage: LocalStorageProtocol

    init(mnemonic: MnemonicProtocol, localStorage: LocalStorageProtocol) {
        self.mnemonic = mnemonic
        self.localStorage = localStorage
    }

}

extension RestoreInteractor: RestorePresenterDelegate {

    func restoreWallet(withWords words: [String]) {
        if mnemonic.validate(words: words) {
            localStorage.save(words: words)
            presenter?.didRestoreWallet()
        } else {
            presenter?.didFailToRestore()
        }
    }

}
