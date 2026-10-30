import Testing
@testable import WalletCore

struct BackupVerifyWordsSessionTests {
    private typealias Session = BackupVerifyWordsSession

    private let words24 = (1 ... 24).map { "w\($0)" }
    private var words12: [String] {
        Array(words24.prefix(12))
    }

    private let identity: ([Session.Word]) -> [Session.Word] = { $0 }

    @Test func itemCount() {
        #expect(Session.itemCount(wordCount: 12) == 2)
        #expect(Session.itemCount(wordCount: 15) == 2)
        #expect(Session.itemCount(wordCount: 18) == 3)
        #expect(Session.itemCount(wordCount: 21) == 3)
        #expect(Session.itemCount(wordCount: 24) == 4)
        #expect(Session.itemCount(wordCount: 25) == 4)
        #expect(Session.itemCount(wordCount: 5) == 0)
    }

    @Test func initialState24Words() {
        let session = Session(words: words24, shuffle: identity)

        #expect(session.inputItems == [
            .init(index: 1, text: nil, current: true),
            .init(index: 2, text: nil, current: false),
            .init(index: 3, text: nil, current: false),
            .init(index: 4, text: nil, current: false),
        ])
        #expect(session.wordItems.map(\.text) == (1 ... 12).map { "w\($0)" })
        #expect(!session.wordItems.map(\.enabled).contains(false))
        #expect(!session.isCompleted)
    }

    @Test func initialState12Words() {
        let session = Session(words: words12, shuffle: identity)

        #expect(session.inputItems.count == 2)
        #expect(session.wordItems.count == 12)
    }

    @Test func shuffleIsApplied() {
        let session = Session(words: words24, shuffle: { Array($0.reversed()) })

        #expect(session.inputWords.map(\.text) == ["w24", "w23", "w22", "w21"])
        #expect(session.inputItems.map(\.index) == [24, 23, 22, 21])
        #expect(session.wordItems.map(\.text) == (13 ... 24).map { "w\($0)" })
    }

    @Test func correctSelectionAdvances() {
        var session = Session(words: words24, shuffle: identity)

        #expect(session.select(suggestionIndex: 0) == .correct)
        #expect(session.inputItems[0].text == "w1")
        #expect(session.inputItems[0].current == false)
        #expect(session.inputItems[1].current == true)
        #expect(session.wordItems[0].enabled == false)
        #expect(!session.wordItems.dropFirst().map(\.enabled).contains(false))
        #expect(session.validatedWordCount == 1)
    }

    @Test func incorrectSelectionResets() {
        var shuffleCalls = 0
        var session = Session(words: words24, shuffle: { words in
            shuffleCalls += 1
            return words
        })
        #expect(shuffleCalls == 2)

        #expect(session.select(suggestionIndex: 0) == .correct)
        #expect(session.select(suggestionIndex: 5) == .incorrect)

        #expect(session.validatedWordCount == 0)
        #expect(session.inputItems.allSatisfy { $0.text == nil })
        #expect(session.inputItems.map(\.current) == [true, false, false, false])
        #expect(!session.wordItems.map(\.enabled).contains(false))
        #expect(shuffleCalls == 4)
    }

    @Test func completion() {
        var session = Session(words: words24, shuffle: identity)

        #expect(session.select(suggestionIndex: 0) == .correct)
        #expect(session.select(suggestionIndex: 1) == .correct)
        #expect(session.select(suggestionIndex: 2) == .correct)
        #expect(session.select(suggestionIndex: 3) == .completed)
        #expect(session.isCompleted)

        let inputItems = session.inputItems
        let wordItems = session.wordItems

        #expect(session.select(suggestionIndex: 4) == .correct)
        #expect(session.isCompleted)
        #expect(session.validatedWordCount == 4)
        #expect(session.inputItems == inputItems)
        #expect(session.wordItems == wordItems)
    }

    @Test func outOfRangeIndexIsIgnored() {
        var session = Session(words: words24, shuffle: identity)
        let inputItems = session.inputItems
        let wordItems = session.wordItems

        #expect(session.select(suggestionIndex: 99) == .correct)
        #expect(session.validatedWordCount == 0)
        #expect(session.inputItems == inputItems)
        #expect(session.wordItems == wordItems)
    }

    @Test func duplicateWords() {
        // "dup" is at positions 1 and 3; with the identity shuffle input words are positions 1 and 2,
        // and both copies of "dup" are among the suggestions (indexes 0 and 2).
        var phrase = words12
        phrase[0] = "dup"
        phrase[2] = "dup"

        var session = Session(words: phrase, shuffle: identity)
        #expect(session.inputWords.map(\.text) == ["dup", "w2"])

        #expect(session.select(suggestionIndex: 2) == .correct)
        #expect(session.validatedWordCount == 1)
        #expect(session.inputItems[0].text == "dup")
        #expect(session.wordItems[2].enabled == false)
        #expect(session.wordItems[0].enabled == true)
        #expect(session.wordItems.enumerated().filter { !$0.element.enabled }.map(\.offset) == [2])

        #expect(session.select(suggestionIndex: 2) == .incorrect)
        #expect(session.validatedWordCount == 0)
        #expect(!session.wordItems.map(\.enabled).contains(false))
    }
}
