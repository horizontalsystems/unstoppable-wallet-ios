import Foundation

protocol ILocalStorage: class {
    var savedWords: [String]? { get }
    var lightMode: Bool { get set }
    var iUnderstand: Bool { get set }
    var isBiometricOn: Bool { get set }
    var currentLanguage: String? { get set }
    var lastExitDate: Double { get set }
    func save(words: [String])
    func clearWords()
}
