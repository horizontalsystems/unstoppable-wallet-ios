import Foundation

class App {
    static let shared = App()

    let localStorage: ILocalStorage
    let wordsManager: WordsManager

    let lockRouter: LockRouter
    let lockManager: LockManager
    let blurManager: BlurManager

    var adapterManager: AdapterManager!

    init() {
        localStorage = UserDefaultsStorage()
        wordsManager = WordsManager(localStorage: localStorage)

        lockRouter = LockRouter()
        lockManager = LockManager(localStorage: localStorage, wordsManager: wordsManager, pinManager: PinManager.shared, lockRouter: lockRouter)
        blurManager = BlurManager(lockManager: lockManager)

        LocalizationHelper.instance.update(language: localStorage.currentLanguage ?? LocalizationHelper.defaultLanguage)

        initLoggedInState()
    }

    func initLoggedInState() {
        if let words = wordsManager.words {
            adapterManager = AdapterManager(words: words)

            adapterManager.start()
        }
    }

}
