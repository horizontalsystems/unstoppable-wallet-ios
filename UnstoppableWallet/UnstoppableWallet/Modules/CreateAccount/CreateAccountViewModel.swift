import RxSwift
import RxRelay
import RxCocoa

class CreateAccountViewModel {
    private let service: CreateAccountService
    private let disposeBag = DisposeBag()

    private let passphraseCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let passphraseConfirmationCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let clearInputsRelay = PublishRelay<Void>()
    private let openSelectKindRelay = PublishRelay<[AlertViewItem]>()
    private let showErrorRelay = PublishRelay<String>()
    private let finishRelay = PublishRelay<()>()

    init(service: CreateAccountService) {
        self.service = service
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

    var kindDriver: Driver<String?> {
        service.kindObservable.map { $0.title }.asDriver(onErrorJustReturn: nil)
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

    var openSelectKindSignal: Signal<[AlertViewItem]> {
        openSelectKindRelay.asSignal()
    }

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    func onTapKind() {
        let viewItems = service.allKinds.map { type in
            AlertViewItem(text: type.title, selected: type == service.kind)
        }
        openSelectKindRelay.accept(viewItems)
    }

    func onSelectKind(index: Int) {
        service.setKind(index: index)
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
