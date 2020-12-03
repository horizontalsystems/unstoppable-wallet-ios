import Foundation

class WordsValidator {

    func validate(words: [String], confirmationIndexes: [Int], confirmationWords: [String]) throws {
        guard confirmationIndexes.count == confirmationWords.count else {
            throw ValidationError.invalidConfirmation
        }

        for (index, word) in confirmationWords.enumerated() {
            let trimmedWord = word.lowercased().trimmingCharacters(in: .whitespaces)

            guard !trimmedWord.isEmpty else {
                throw ValidationError.emptyWords
            }

            guard words[confirmationIndexes[index] - 1] == trimmedWord else {
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
                case .emptyWords:
                    return "words_validator.empty_words".localized
                case .invalidConfirmation:
                    return "words_validator.invalid_confirmation".localized
            }
        }
    }

}
