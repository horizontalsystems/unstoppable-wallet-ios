import RxSwift
import RxRelay
import RxCocoa
import HdWalletKit

class CreateAccountViewModel {
    private let service: CreateAccountService
    private let disposeBag = DisposeBag()

    private let wordCountRelay = BehaviorRelay<String>(value: "")
    private let passphraseCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let passphraseConfirmationCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let clearInputsRelay = PublishRelay<Void>()
    private let showErrorRelay = PublishRelay<String>()
    private let finishRelay = PublishRelay<()>()

    init(service: CreateAccountService) {
        self.service = service

        subscribe(disposeBag, service.wordCountObservable) { [weak self] in self?.sync(wordCount: $0) }

        sync(wordCount: service.wordCount)
    }

    private func sync(wordCount: Mnemonic.WordCount) {
        wordCountRelay.accept("create_wallet.n_words".localized("\(wordCount.rawValue)"))
    }

    private func clearInputs() {
        clearInputsRelay.accept(())
        clearCautions()

        service.passphrase = ""
        service.passphraseConfirmation = ""
    }

    private func clearCautions() {
        if passphraseCautionRelay.value != nil {
            passphraseCautionRelay.accept(nil)
        }

        if passphraseConfirmationCautionRelay.value != nil {
            passphraseConfirmationCautionRelay.accept(nil)
        }
    }

}

extension CreateAccountViewModel {

    var wordCountDriver: Driver<String> {
        wordCountRelay.asDriver()
    }

    var inputsVisibleDriver: Driver<Bool> {
        service.passphraseEnabledObservable.asDriver(onErrorJustReturn: false)
    }

    var passphraseCautionDriver: Driver<Caution?> {
        passphraseCautionRelay.asDriver()
    }

    var passphraseConfirmationCautionDriver: Driver<Caution?> {
        passphraseConfirmationCautionRelay.asDriver()
    }

    var clearInputsSignal: Signal<Void> {
        clearInputsRelay.asSignal()
    }

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var namePlaceholder: String {
        service.defaultAccountName
    }

    var wordCountViewItems: [AlertViewItem] {
        Mnemonic.WordCount.allCases.map { wordCount in
            let title: String
            switch wordCount {
            case .twelve: title = "create_wallet.12_words".localized
            default: title = "create_wallet.n_words".localized("\(wordCount.rawValue)")
            }

            return AlertViewItem(text: title, selected: wordCount == service.wordCount)
        }
    }

    func onChange(name: String) {
        service.name = name
    }

    func onSelectWordCount(index: Int) {
        service.set(wordCount: Mnemonic.WordCount.allCases[index])
    }

    func onTogglePassphrase(isOn: Bool) {
        service.set(passphraseEnabled: isOn)
        clearInputs()
    }

    func onChange(passphrase: String) {
        service.passphrase = passphrase
        clearCautions()
    }

    func onChange(passphraseConfirmation: String) {
        service.passphraseConfirmation = passphraseConfirmation
        clearCautions()
    }

    func validatePassphrase(text: String?) -> Bool {
        let validated = service.validate(text: text)
        if !validated {
            passphraseCautionRelay.accept(Caution(text: "create_wallet.error.forbidden_symbols".localized, type: .warning))
        }
        return validated
    }

    func validatePassphraseConfirmation(text: String?) -> Bool {
        let validated = service.validate(text: text)
        if !validated {
            passphraseConfirmationCautionRelay.accept(Caution(text: "create_wallet.error.forbidden_symbols".localized, type: .warning))
        }
        return validated
    }

    func onTapCreate() {
        passphraseCautionRelay.accept(nil)
        passphraseConfirmationCautionRelay.accept(nil)
        do {
            try service.createAccount()
            finishRelay.accept(())
        } catch {
            if case CreateAccountService.CreateError.emptyPassphrase = error {
                passphraseCautionRelay.accept(Caution(text: "create_wallet.error.empty_passphrase".localized, type: .error))
            } else if case CreateAccountService.CreateError.invalidConfirmation = error {
                passphraseConfirmationCautionRelay.accept(Caution(text: "create_wallet.error.invalid_confirmation".localized, type: .error))
            } else {
                showErrorRelay.accept(error.smartDescription)
            }
        }
    }

}
