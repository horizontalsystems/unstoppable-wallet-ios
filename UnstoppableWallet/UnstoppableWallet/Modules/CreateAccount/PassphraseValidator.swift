import Foundation

class PassphraseValidator {
    static private let forbiddenSymbols = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '\"`&/?!:;.,~*$=+-[](){}<>\\_#@|%").inverted

    static func validate(text: String?) -> Bool {
        if text?.rangeOfCharacter(from: Self.forbiddenSymbols) != nil {
            return false
        }

        return true
    }

}
