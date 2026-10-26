struct BackupVerifyWordsSession {
    static let suggestionCount = 12

    private let words: [Word]
    private let itemCount: Int
    private let shuffle: ([Word]) -> [Word]

    private(set) var inputWords: [Word] = []
    private(set) var suggestionWords: [Word] = []
    private(set) var validatedWordCount = 0
    private var validatedSuggestionIndexes: Set<Int> = []

    init(words: [String], shuffle: @escaping ([Word]) -> [Word] = { $0.shuffled() }) {
        self.words = words.enumerated().map { index, word in Word(index: index + 1, text: word) }
        itemCount = Self.itemCount(wordCount: words.count)
        self.shuffle = shuffle

        reset()
    }

    static func itemCount(wordCount: Int) -> Int {
        wordCount / 6
    }

    var inputItems: [InputItem] {
        inputWords.enumerated().map { index, word in
            InputItem(
                index: word.index,
                text: index < validatedWordCount ? word.text : nil,
                current: index == validatedWordCount
            )
        }
    }

    var wordItems: [WordItem] {
        suggestionWords.enumerated().map { index, word in
            WordItem(text: word.text, enabled: !validatedSuggestionIndexes.contains(index))
        }
    }

    var isCompleted: Bool {
        !inputWords.isEmpty && validatedWordCount == inputWords.count
    }

    mutating func reset() {
        let selectedWords = Array(shuffle(words).prefix(Self.suggestionCount))
        inputWords = Array(selectedWords.prefix(itemCount))
        suggestionWords = shuffle(selectedWords)
        validatedWordCount = 0
        validatedSuggestionIndexes = []
    }

    mutating func select(suggestionIndex: Int) -> Outcome {
        guard validatedWordCount < inputWords.count, suggestionWords.indices.contains(suggestionIndex) else {
            return .correct
        }

        guard !validatedSuggestionIndexes.contains(suggestionIndex),
              inputWords[validatedWordCount].text == suggestionWords[suggestionIndex].text
        else {
            reset()
            return .incorrect
        }

        validatedSuggestionIndexes.insert(suggestionIndex)
        validatedWordCount += 1

        return validatedWordCount == inputWords.count ? .completed : .correct
    }
}

extension BackupVerifyWordsSession {
    struct Word: Equatable {
        let index: Int
        let text: String
    }

    struct InputItem: Equatable {
        let index: Int
        let text: String?
        let current: Bool
    }

    struct WordItem: Equatable {
        let text: String
        let enabled: Bool
    }

    enum Outcome: Equatable {
        case correct
        case incorrect
        case completed
    }
}
