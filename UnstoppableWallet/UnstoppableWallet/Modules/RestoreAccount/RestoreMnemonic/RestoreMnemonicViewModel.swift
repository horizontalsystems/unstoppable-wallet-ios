import Foundation
import RxSwift
import RxRelay
import RxCocoa

class RestoreMnemonicViewModel {
    private let service: RestoreMnemonicService
    private let disposeBag = DisposeBag()

    private let possibleWordsRelay = BehaviorRelay<[String]>(value: [])
    private let invalidRangesRelay = BehaviorRelay<[NSRange]>(value: [])
    private let replaceWordRelay = PublishRelay<(NSRange, String)>()

    private let mnemonicCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let passphraseCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let clearInputsRelay = PublishRelay<Void>()

    private var cursorOffset = 0

    init(service: RestoreMnemonicService) {
        self.service = service
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

    private func hasCursor(item: RestoreMnemonicService.WordItem) -> Bool {
        cursorOffset >= item.range.lowerBound && cursorOffset <= item.range.upperBound
    }

    private var cursorItem: RestoreMnemonicService.WordItem? {
        service.items.first { hasCursor(item: $0) }
    }

}

extension RestoreMnemonicViewModel {

    var possibleWordsDriver: Driver<[String]> {
        possibleWordsRelay.asDriver()
    }

    var invalidRangesDriver: Driver<[NSRange]> {
        invalidRangesRelay.asDriver()
    }

    var replaceWordSignal: Signal<(NSRange, String)> {
        replaceWordRelay.asSignal()
    }

    var inputsVisibleDriver: Driver<Bool> {
        service.passphraseEnabledObservable.asDriver(onErrorJustReturn: false)
    }

    var mnemonicCautionDriver: Driver<Caution?> {
        mnemonicCautionRelay.asDriver()
    }

    var passphraseCautionDriver: Driver<Caution?> {
        passphraseCautionRelay.asDriver()
    }

    var clearInputsSignal: Signal<Void> {
        clearInputsRelay.asSignal()
    }

    func onChange(text: String, cursorOffset: Int, language: String?) {
        self.cursorOffset = cursorOffset
        service.set(language: language)
        service.syncItems(text: text)

        mnemonicCautionRelay.accept(nil)

        let nonCursorInvalidItems = service.items.filter { item in
            switch item.type {
            case .correct: return false
            case .incorrect: return true
            case .correctPrefix: return !hasCursor(item: item)
            }
        }

        invalidRangesRelay.accept(nonCursorInvalidItems.map { $0.range })

        if let cursorItem = cursorItem {
            let possibleWords = service.possibleWords(string: cursorItem.word)
            possibleWordsRelay.accept(possibleWords)
        } else {
            possibleWordsRelay.accept([])
        }
    }

    func onSelect(word: String) {
        guard let cursorItem = cursorItem else {
            return
        }

        replaceWordRelay.accept((cursorItem.range, word))
    }

    func onTogglePassphrase(isOn: Bool) {
        service.set(passphraseEnabled: isOn)
        clearInputs()
    }

    func onChange(passphrase: String) {
        service.passphrase = passphrase
        clearCautions()
    }

}

extension RestoreMnemonicViewModel: IRestoreSubViewModel {

    func resolveAccountType() -> AccountType? {
        mnemonicCautionRelay.accept(nil)
        passphraseCautionRelay.accept(nil)

        guard service.items.allSatisfy({ $0.type == .correct }) else {
            invalidRangesRelay.accept(service.items.filter { $0.type != .correct }.map { $0.range })
            return nil
        }

        do {
            return try service.accountType(words: service.items.map { $0.word })
        } catch RestoreMnemonicService.ErrorList.errors(let errors) {
            errors.forEach { error in
                if case RestoreMnemonicService.RestoreError.emptyPassphrase = error {
                    passphraseCautionRelay.accept(Caution(text: "restore.error.empty_passphrase".localized, type: .error))
                } else {
                    mnemonicCautionRelay.accept(Caution(text: error.convertedError.smartDescription, type: .error))
                }
            }
            return nil
        } catch {
            return nil
        }
    }

    func clear() {
    }

}
