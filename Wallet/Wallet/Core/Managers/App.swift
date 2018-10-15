import Foundation

class App {
    static let shared = App()

    private let fallbackLanguage = "en"

    let secureStorage: ISecureStorage
    let localStorage: ILocalStorage
    let wordsManager: WordsManager

    let pinManager: PinManager
    let lockRouter: LockRouter
    let lockManager: LockManager
    let blurManager: BlurManager

    let localizationManager: LocalizationManager
    let languageManager: ILanguageManager

    var adapterManager: AdapterManager!

    init() {
        secureStorage = KeychainStorage()
        localStorage = UserDefaultsStorage()
        wordsManager = WordsManager(secureStorage: secureStorage, localStorage: localStorage)

        pinManager = PinManager(secureStorage: secureStorage)
        lockRouter = LockRouter()
        lockManager = LockManager(localStorage: localStorage, wordsManager: wordsManager, pinManager: pinManager, lockRouter: lockRouter)
        blurManager = BlurManager(lockManager: lockManager)

        localizationManager = LocalizationManager()
        languageManager = LanguageManager(localizationManager: localizationManager, localStorage: localStorage, fallbackLanguage: fallbackLanguage)

        initLoggedInState()
    }

    func initLoggedInState() {
        if let words = wordsManager.words {
            adapterManager = AdapterManager(words: words)

            adapterManager.start()
        }
    }

}
