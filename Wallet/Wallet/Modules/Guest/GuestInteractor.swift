import Foundation
import RxSwift

class GuestInteractor {
    private let disposeBag = DisposeBag()

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
        do {
            let words = try mnemonic.generateWords()
            localStorage.save(words: words)
            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}
