import Foundation

class App {
    static let shared = App()

    let secureStorage: ISecureStorage
    let localStorage: ILocalStorage
    let wordsManager: WordsManager

    let pinManager: PinManager
    let lockRouter: LockRouter
    let lockManager: LockManager
    let blurManager: BlurManager

    var adapterManager: AdapterManager!

    init() {
        secureStorage = KeychainStorage()
        localStorage = UserDefaultsStorage()
        wordsManager = WordsManager(secureStorage: secureStorage, localStorage: localStorage)

        pinManager = PinManager(secureStorage: secureStorage)
        lockRouter = LockRouter()
        lockManager = LockManager(localStorage: localStorage, wordsManager: wordsManager, pinManager: pinManager, lockRouter: lockRouter)
        blurManager = BlurManager(lockManager: lockManager)

        LocalizationManager.instance.update(language: localStorage.currentLanguage ?? LocalizationManager.defaultLanguage)

        initLoggedInState()
    }

    func initLoggedInState() {
        if let words = wordsManager.words {
            adapterManager = AdapterManager(words: words)

            adapterManager.start()
        }
    }

}
