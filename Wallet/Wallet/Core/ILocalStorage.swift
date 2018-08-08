import Foundation

protocol ILocalStorage: class {
    var savedWords: [String]? { get }
    func save(words: [String])
    func clearWords()
}
