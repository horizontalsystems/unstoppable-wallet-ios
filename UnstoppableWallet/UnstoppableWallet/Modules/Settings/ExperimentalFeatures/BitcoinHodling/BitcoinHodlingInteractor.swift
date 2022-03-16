import RxSwift

class BitcoinHodlingInteractor {
    private let localStorage: LocalStorage

    init(localStorage: LocalStorage) {
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
