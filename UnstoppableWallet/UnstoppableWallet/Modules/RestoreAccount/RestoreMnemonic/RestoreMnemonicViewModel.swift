import Foundation
import RxSwift
import RxRelay
import RxCocoa

class RestoreMnemonicViewModel {
    private let service: RestoreMnemonicService
    private let disposeBag = DisposeBag()

    private let invalidRangesRelay = BehaviorRelay<[NSRange]>(value: [])
    private let proceedRelay = PublishRelay<AccountType>()
    private let showErrorRelay = PublishRelay<String>()

    private let passphraseCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let clearInputsRelay = PublishRelay<Void>()

    private let regex = try! NSRegularExpression(pattern: "\\S+")
    private var state = State(allItems: [], invalidItems: [])

    init(service: RestoreMnemonicService) {
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
            !service.doesWordExist(word: item.word)
        }

        state = State(allItems: allItems, invalidItems: invalidItems)
    }

    private func clearInputs() {
        clearInputsRelay.accept(())
        clearCautions()

        service.passphrase = ""
    }

    private func clearCautions() {
        if passphraseCautionRelay.value != nil {
            passphraseCautionRelay.accept(nil)
        }
    }

    func validatePassphrase(text: String?) -> Bool {
        let validated = service.validate(text: text)
        if !validated {
            passphraseCautionRelay.accept(Caution(text: "create_wallet.error.forbidden_symbols".localized, type: .warning))
        }
        return validated
    }

}

extension RestoreMnemonicViewModel {

    var invalidRangesDriver: Driver<[NSRange]> {
        invalidRangesRelay.asDriver()
    }

    var proceedSignal: Signal<AccountType> {
        proceedRelay.asSignal()
    }

    var inputsVisibleDriver: Driver<Bool> {
        service.passphraseEnabledObservable.asDriver(onErrorJustReturn: false)
    }

    var passphraseCautionDriver: Driver<Caution?> {
        passphraseCautionRelay.asDriver()
    }

    var clearInputsSignal: Signal<Void> {
        clearInputsRelay.asSignal()
    }

    func onChange(text: String, cursorOffset: Int) {
        syncState(text: text)

        let nonCursorInvalidItems = state.invalidItems.filter { item in
            let hasCursor = cursorOffset >= item.range.lowerBound && cursorOffset <= item.range.upperBound

            return !hasCursor || !service.doesWordPartiallyExist(word: item.word)
        }

        invalidRangesRelay.accept(nonCursorInvalidItems.map { $0.range })
    }

    func onTogglePassphrase(isOn: Bool) {
        service.set(passphraseEnabled: isOn)
        clearInputs()
    }

    func onChange(passphrase: String) {
        service.passphrase = passphrase
        clearCautions()
    }

    func onTapProceed() {
        passphraseCautionRelay.accept(nil)

        guard state.invalidItems.isEmpty else {
            invalidRangesRelay.accept(state.invalidItems.map { $0.range })
            return
        }

        do {
            let accountType = try service.accountType(words: state.allItems.map { $0.word })

            proceedRelay.accept(accountType)
        } catch {
            if case RestoreMnemonicService.RestoreError.emptyPassphrase = error {
                passphraseCautionRelay.accept(Caution(text: "restore.error.empty_passphrase".localized, type: .error))
            } else {
                showErrorRelay.accept(error.convertedError.smartDescription)
            }
        }
    }

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
    }

}

extension RestoreMnemonicViewModel {

    private struct WordItem {
        let word: String
        let range: NSRange
    }

    private struct State {
        let allItems: [WordItem]
        let invalidItems: [WordItem]
    }

}
