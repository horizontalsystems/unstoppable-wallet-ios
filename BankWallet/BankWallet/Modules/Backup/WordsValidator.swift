import Foundation

class WordsValidator {
    private let words: [String]

    init(words: [String]) {
        self.words = words
    }

    func validate(confirmationWords: [Int: String]) throws {
        for (index, word) in confirmationWords {
            let trimmedWord = word.trimmingCharacters(in: .whitespaces)

            guard !trimmedWord.isEmpty else {
                throw ValidationError.emptyWords
            }

            guard words[index - 1] == trimmedWord else {
                throw ValidationError.invalidConfirmation
            }
        }
    }

}

extension WordsValidator {

    enum ValidationError: LocalizedError {
        case emptyWords
        case invalidConfirmation

        var errorDescription: String? {
            switch self {
            case .emptyWords: return "words_validator.empty_words".localized
            case .invalidConfirmation: return "words_validator.invalid_confirmation".localized
            }
        }
    }

}
