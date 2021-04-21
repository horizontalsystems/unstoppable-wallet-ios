import RxSwift
import RxRelay
import RxCocoa

class ShowKeyViewModel {
    private let service: ShowKeyService
    private let disposeBag = DisposeBag()

    private let openUnlockRelay = PublishRelay<()>()
    private let showKeyRelay = PublishRelay<()>()

    init(service: ShowKeyService) {
        self.service = service
    }

}

extension ShowKeyViewModel {

    var openUnlockSignal: Signal<()> {
        openUnlockRelay.asSignal()
    }

    var showKeySignal: Signal<()> {
        showKeyRelay.asSignal()
    }

    var words: [String] {
        service.words
    }

    var passphrase: String? {
        service.salt.isEmpty ? nil : service.salt
    }

    var privateKeys: [PrivateKey] {
        var keys = [PrivateKey]()

        if let value = service.evmPrivateKey {
            keys.append(PrivateKey(blockchain: "Ethereum / Binance Smart Chain", value: value))
        }

        return keys
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

}

extension ShowKeyViewModel {

    struct PrivateKey {
        let blockchain: String
        let value: String
    }

}
