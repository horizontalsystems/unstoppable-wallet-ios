import Foundation

class MainInteractor {
    weak var delegate: IMainInteractorDelegate?

    private let localStorage: ILocalStorage

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

}

extension MainInteractor: IMainInteractor {

    func setDidShowMainOnce() {
        DispatchQueue.global(qos: .background).async {
            self.localStorage.didShowMainOnce = true
        }
    }

}
