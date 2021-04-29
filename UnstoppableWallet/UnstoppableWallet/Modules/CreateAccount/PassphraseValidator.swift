import Foundation

class PassphraseValidator: ITextValidator  {
    static private let forbiddenSymbols = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789").inverted

    func validate(text: String?) -> Bool {
        if text?.rangeOfCharacter(from: Self.forbiddenSymbols) != nil {
            return false
        }

        return true
    }

}

extension PassphraseValidator {

    enum ValidationError: Error {
        case whitespacesAndNewlines
    }

}
