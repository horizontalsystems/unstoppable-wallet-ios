import Foundation

class App {
    static let shared = App()

    let localStorage: ILocalStorage
    let wordsManager: WordsManager

    var adapterManager: AdapterManager!

    init() {
        localStorage = UserDefaultsStorage()
        wordsManager = WordsManager(localStorage: localStorage)

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
