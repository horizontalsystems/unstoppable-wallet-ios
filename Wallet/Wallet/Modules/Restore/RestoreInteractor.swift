import Foundation
import RxSwift

class RestoreInteractor {

    private let disposeBag = DisposeBag()

    weak var delegate: IRestoreInteractorDelegate?

    private let mnemonic: IMnemonic
    private let localStorage: ILocalStorage

    init(mnemonic: IMnemonic, localStorage: ILocalStorage) {
        self.mnemonic = mnemonic
        self.localStorage = localStorage
    }

}

extension RestoreInteractor: IRestoreInteractor {

    func restore(withWords words: [String]) {
        do {
            try mnemonic.validate(words: words)
            localStorage.save(words: words)
            delegate?.didRestore()
        } catch {
            delegate?.didFailToRestore(withError: error)
        }
    }

}
