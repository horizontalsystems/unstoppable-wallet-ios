import Foundation
import RxSwift
import RxRelay
import RxCocoa

class RestoreWordsViewModel {
    private let service: RestoreWordsService
    private let disposeBag = DisposeBag()

    private let invalidRangesRelay = BehaviorRelay<[NSRange]>(value: [])
    private let accountTypeRelay = PublishRelay<AccountType>()
    private let errorRelay = PublishRelay<String>()

    private let regex = try! NSRegularExpression(pattern: "\\S+")
    private var state = State(allItems: [], invalidItems: [])
    private var birthdayHeight: Int?

    init(service: RestoreWordsService) {
        self.service = service
    }

    private func wordItems(text: String) -> [WordItem] {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))

        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else {
                return nil
            }

            let word = String(text[range]).lowercased()

            return WordItem(word: word, range: match.range)
        }
    }

    private func syncState(text: String) {
        let allItems = wordItems(text: text)
        let invalidItems = allItems.filter { item in
            !service.isWordExists(word: item.word)
        }

        state = State(allItems: allItems, invalidItems: invalidItems)
    }

}

extension RestoreWordsViewModel {

    var invalidRangesDriver: Driver<[NSRange]> {
        invalidRangesRelay.asDriver()
    }

    var accountTypeSignal: Signal<AccountType> {
        accountTypeRelay.asSignal()
    }

    var wordCount: Int {
        service.wordCount
    }

    var accountTitle: String {
        service.accountTitle
    }

    var birthdayHeightEnabled: Bool {
        service.birthdayHeightEnabled
    }

    func onChange(text: String, cursorOffset: Int) {
        syncState(text: text)

        let nonCursorInvalidItems = state.invalidItems.filter { item in
            let hasCursor = cursorOffset >= item.range.lowerBound && cursorOffset <= item.range.upperBound

            return !hasCursor || !service.isWordPartiallyExists(word: item.word)
        }

        invalidRangesRelay.accept(nonCursorInvalidItems.map { $0.range })
    }

    func onChange(birthdayHeight: String?) {
        self.birthdayHeight = birthdayHeight.flatMap { Int($0) }
    }

    func onTapProceed() {
        guard state.invalidItems.isEmpty else {
            invalidRangesRelay.accept(state.invalidItems.map { $0.range })
            return
        }

        do {
            let accountType = try service.accountType(words: state.allItems.map { $0.word }, birthdayHeight: birthdayHeight)

            accountTypeRelay.accept(accountType)
        } catch {
            errorRelay.accept(error.convertedError.smartDescription)
        }
    }

    var errorSignal: Signal<String> {
        errorRelay.asSignal()
    }

}

extension RestoreWordsViewModel {

    private struct WordItem {
        let word: String
        let range: NSRange
    }

    private struct State {
        let allItems: [WordItem]
        let invalidItems: [WordItem]
    }

}
