import Foundation

protocol ILocalStorage {
    var savedWords: [String]? { get }
    func save(words: [String])
    func clearWords()
}
