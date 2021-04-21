import RxSwift
import RxRelay
import RxCocoa

class BackupKeyViewModel {
    private let service: BackupKeyService
    private let disposeBag = DisposeBag()

    private let openUnlockRelay = PublishRelay<()>()
    private let showKeyRelay = PublishRelay<()>()
    private let openConfirmRelay = PublishRelay<Account>()

    init(service: BackupKeyService) {
        self.service = service
    }

}

extension BackupKeyViewModel {

    var openUnlockSignal: Signal<()> {
        openUnlockRelay.asSignal()
    }

    var showKeySignal: Signal<()> {
        showKeyRelay.asSignal()
    }

    var openConfirmSignal: Signal<Account> {
        openConfirmRelay.asSignal()
    }

    var words: [String] {
        service.words
    }

    var passphrase: String? {
        service.salt.isEmpty ? nil : service.salt
    }

    func onTapShow() {
        if service.isPinSet {
            openUnlockRelay.accept(())
        } else {
            showKeyRelay.accept(())
        }
    }

    func onUnlock() {
        showKeyRelay.accept(())
    }

    func onTapBackup() {
        openConfirmRelay.accept(service.account)
    }

}
