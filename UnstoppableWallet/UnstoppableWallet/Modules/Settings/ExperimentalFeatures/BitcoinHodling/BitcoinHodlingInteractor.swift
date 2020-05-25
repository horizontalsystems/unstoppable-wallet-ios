import RxSwift

class BitcoinHodlingInteractor {
    private let localStorage: ILocalStorage

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

}

extension BitcoinHodlingInteractor: IBitcoinHodlingInteractor {

    var lockTimeEnabled: Bool {
        get {
            localStorage.lockTimeEnabled
        }
        set {
            localStorage.lockTimeEnabled = newValue
        }
    }

}
