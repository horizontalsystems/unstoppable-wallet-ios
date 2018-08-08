import Foundation

class UserDefaultsStorage: ILocalStorage {
    static let shared = UserDefaultsStorage()

    private let keyWords = "mnemonic_words"

    var savedWords: [String]? {
        if let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String {
            return wordsString.split(separator: " ").map(String.init)
        }
        return nil
    }

    func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    func clearWords() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

}
