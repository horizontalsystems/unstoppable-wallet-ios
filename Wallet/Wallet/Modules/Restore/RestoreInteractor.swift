import Foundation
import RxSwift

class RestoreInteractor {

    enum ValidationError: Error {
        case invalidWords
    }

    private let disposeBag = DisposeBag()

    weak var delegate: IRestoreInteractorDelegate?

    private let mnemonic: IMnemonic
    private let loginManager: LoginManager

    init(mnemonic: IMnemonic, loginManager: LoginManager) {
        self.mnemonic = mnemonic
        self.loginManager = loginManager
    }

}

extension RestoreInteractor: IRestoreInteractor {

    func restore(withWords words: [String]) {
        let validationObservable = mnemonic.validate(words: words) ? Observable.just(words) : Observable.error(ValidationError.invalidWords)

        validationObservable
                .flatMap { words in
                    self.loginManager.login(withWords: words)
                }
                .subscribeAsync(disposeBag: disposeBag, onError: { [weak self] _ in
                    self?.delegate?.didFailToRestore()
                }, onCompleted: { [weak self] in
                    self?.delegate?.didRestore()
                })
    }

}
