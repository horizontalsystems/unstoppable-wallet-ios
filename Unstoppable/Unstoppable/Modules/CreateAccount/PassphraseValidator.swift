import Foundation

enum PassphraseValidator {
    private static let forbiddenSymbols = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '\"`&/?!:;.,~*$=+-[](){}<>\\_#@|%").inverted

    static func validate(text: String?) -> Bool {
        if text?.rangeOfCharacter(from: forbiddenSymbols) != nil {
            return false
        }

        return true
    }
}
