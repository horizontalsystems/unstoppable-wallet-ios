import RxSwift
import RxRelay

class BackupVerifyWordsService {
    let account: Account
    private let accountManager: AccountManager
    private let words: [Word]
    private let hasSalt: Bool
    private let itemCount: Int
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = State(inputItems: [], wordItems: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var inputWords = [Word]()
    private var suggestionWords = [Word]()
    private var validatedWordCount = 0

    init?(account: Account, accountManager: AccountManager, appManager: IAppManager) {
        guard case let .mnemonic(words, salt) = account.type else {
            return nil
        }

        self.account = account
        self.accountManager = accountManager
        self.words = words.enumerated().map { index, word in Word(index: index + 1, text: word) }
        hasSalt = !salt.isEmpty

        itemCount = words.count / 6

        subscribe(disposeBag, appManager.didBecomeActiveObservable) { [weak self] in self?.reset() }

        reset()
    }

    private func syncState() {
        let validatedWords = inputWords.prefix(validatedWordCount)

        state = State(
                inputItems: inputWords.enumerated().map { index, word in
                    InputItem(
                            index: word.index,
                            text: validatedWords.contains(word) ? word.text : nil,
                            current: index == validatedWordCount
                    )
                },
                wordItems: suggestionWords.map { word in
                    WordItem(
                            text: word.text,
                            enabled: !validatedWords.contains(word)
                    )
                }
        )
    }

}

extension BackupVerifyWordsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func handleSelectedWord(index: Int) -> ActionResult {
        let inputWord = inputWords[validatedWordCount]
        let word = suggestionWords[index]

        guard inputWord == word else {
            reset()
            return .incorrect
        }

        validatedWordCount += 1

        syncState()

        if validatedWordCount == inputWords.count {
//            if hasSalt {
//                return .showPassphrase
//            } else {
                account.backedUp = true
                accountManager.update(account: account)

                return .backedUp
//            }
        } else {
            return .correct
        }
    }

    func reset() {
        let selectedWords = words.shuffled().prefix(12)
        inputWords = Array(selectedWords.prefix(itemCount))
        suggestionWords = selectedWords.shuffled()
        validatedWordCount = 0

        syncState()
    }

}

extension BackupVerifyWordsService {

    enum ActionResult {
        case correct
        case incorrect
        case showPassphrase
        case backedUp
    }

    struct State {
        let inputItems: [InputItem]
        let wordItems: [WordItem]
    }

    struct WordItem {
        let text: String
        let enabled: Bool
    }

    struct InputItem {
        let index: Int
        let text: String?
        let current: Bool
    }

    struct Word: Equatable {
        let index: Int
        let text: String

        static func ==(lhs: Word, rhs: Word) -> Bool {
            lhs.index == rhs.index
        }
    }

}
