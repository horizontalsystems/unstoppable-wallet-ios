import Foundation

class UserDefaultsStorage: LocalStorageProtocol {

    private(set) var savedWords: [String]?

    func save(words: [String]) {
        savedWords = words
    }

}
