import RxSwift
import RxRelay
import RxCocoa

class ManageAccountViewModel {
    private let service: ManageAccountService
    private let disposeBag = DisposeBag()

    private let keyActionStateRelay = BehaviorRelay<KeyActionState>(value: .none)
    private let saveEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let openUnlockRelay = PublishRelay<()>()
    private let openRecoveryPhraseRelay = PublishRelay<Account>()
    private let openEvmPrivateKeyRelay = PublishRelay<Account>()
    private let openPublicKeysRelay = PublishRelay<Account>()
    private let openBackupKeyRelay = PublishRelay<Account>()
    private let openUnlinkRelay = PublishRelay<Account>()
    private let finishRelay = PublishRelay<()>()

    private(set) var additionalViewItems = [AdditionalViewItem]()

    private var unlockRequest: UnlockRequest = .recoveryPhrase

    init(service: ManageAccountService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.accountObservable) { [weak self] in self?.sync(account: $0) }
        subscribe(disposeBag, service.accountDeletedObservable) { [weak self] in self?.finishRelay.accept(()) }

        sync(state: service.state)
        sync(account: service.account)
        syncAccountSettings()
    }

    private func sync(state: ManageAccountService.State) {
        switch state {
        case .cannotSave: saveEnabledRelay.accept(false)
        case .canSave: saveEnabledRelay.accept(true)
        }
    }

    private func sync(account: Account) {
        let keyAccountState: KeyActionState

        switch account.type {
        case .address:
            keyAccountState = .none
        default:
            keyAccountState = account.backedUp ? .showRecoveryPhrase : .backupRecoveryPhrase
        }

        keyActionStateRelay.accept(keyAccountState)
    }

    private func syncAccountSettings() {
        additionalViewItems = service.accountSettingsInfo.map { coin, restoreSettingType, value in
            AdditionalViewItem(
                    imageUrl: coin.imageUrl,
                    title: restoreSettingType.title(coin: coin),
                    value: value
            )
        }
    }

}

extension ManageAccountViewModel {

    var saveEnabledDriver: Driver<Bool> {
        saveEnabledRelay.asDriver()
    }

    var keyActionStateDriver: Driver<KeyActionState> {
        keyActionStateRelay.asDriver()
    }

    var openUnlockSignal: Signal<()> {
        openUnlockRelay.asSignal()
    }

    var openRecoveryPhraseSignal: Signal<Account> {
        openRecoveryPhraseRelay.asSignal()
    }

    var openEvmPrivateKeySignal: Signal<Account> {
        openEvmPrivateKeyRelay.asSignal()
    }

    var openPublicKeysSignal: Signal<Account> {
        openPublicKeysRelay.asSignal()
    }

    var openBackupKeySignal: Signal<Account> {
        openBackupKeyRelay.asSignal()
    }

    var openUnlinkSignal: Signal<Account> {
        openUnlinkRelay.asSignal()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var accountName: String {
        service.account.name
    }

    func onUnlock() {
        switch unlockRequest {
        case .recoveryPhrase: openRecoveryPhraseRelay.accept(service.account)
        case .evmPrivateKey: openEvmPrivateKeyRelay.accept(service.account)
        }
    }

    func onChange(name: String?) {
        service.set(name: name ?? "")
    }

    func onSave() {
        service.saveAccount()
        finishRelay.accept(())
    }

    func onTapRecoveryPhrase() {
        if service.isPinSet {
            unlockRequest = .recoveryPhrase
            openUnlockRelay.accept(())
        } else {
            openRecoveryPhraseRelay.accept(service.account)
        }
    }

    func onTapEvmPrivateKey() {
        if service.isPinSet {
            unlockRequest = .evmPrivateKey
            openUnlockRelay.accept(())
        } else {
            openEvmPrivateKeyRelay.accept(service.account)
        }
    }

    func onTapPublicKeys() {
        openPublicKeysRelay.accept(service.account)
    }

    func onTapBackupKey() {
        openBackupKeyRelay.accept(service.account)
    }

    func onTapUnlink() {
        openUnlinkRelay.accept(service.account)
    }

}

extension ManageAccountViewModel {

    enum UnlockRequest {
        case recoveryPhrase
        case evmPrivateKey
    }

    enum KeyActionState {
        case none
        case showRecoveryPhrase
        case backupRecoveryPhrase
    }

    struct AdditionalViewItem {
        let imageUrl: String
        let title: String
        let value: String
    }

}
