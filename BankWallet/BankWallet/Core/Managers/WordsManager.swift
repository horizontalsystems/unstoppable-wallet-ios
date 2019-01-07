import HSHDWalletKit
import RxSwift

class WordsManager {
    private let secureStorage: ISecureStorage
    private let localStorage: ILocalStorage

    let loggedInSubject: PublishSubject<Bool> = PublishSubject()
    let backedUpSubject: PublishSubject<Bool> = PublishSubject()

    private(set) var authData: AuthData?

    init(secureStorage: ISecureStorage, localStorage: ILocalStorage) {
        self.secureStorage = secureStorage
        self.localStorage = localStorage

        authData = secureStorage.authData
    }

}

extension WordsManager: IWordsManager {

    var words: [String]? {
        return authData?.words
    }

    var isBackedUp: Bool {
        get {
            return localStorage.isBackedUp
        }
        set {
            localStorage.isBackedUp = newValue
            backedUpSubject.onNext(newValue)
        }
    }

    var isLoggedIn: Bool {
        return authData != nil
    }

    func createWords() throws {
        let authData = AuthData(words: try Mnemonic.generate())
        try secureStorage.set(authData: authData)
        self.authData = authData

        loggedInSubject.onNext(true)
    }

    func validate(words: [String]) throws {
        try Mnemonic.validate(words: words)
    }

    func restore(withWords words: [String]) throws {
        try Mnemonic.validate(words: words)

        let authData = AuthData(words: words)
        try secureStorage.set(authData: authData)
        self.authData = authData

        isBackedUp = true
        loggedInSubject.onNext(true)
    }

    func logout() {
        try? secureStorage.set(authData: nil)
        authData = nil
        localStorage.clear()

        loggedInSubject.onNext(false)
    }

}
