import Foundation

class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    let mnemonic: IMnemonic
    let localStorage: ILocalStorage

    init(mnemonic: IMnemonic, localStorage: ILocalStorage) {
        self.mnemonic = mnemonic
        self.localStorage = localStorage
    }

}

extension RestoreInteractor: IRestoreInteractor {

    func restore(withWords words: [String]) {
        if mnemonic.validate(words: words) {
            localStorage.save(words: words)
            delegate?.didRestore()
        } else {
            delegate?.didFailToRestore()
        }
    }

}
