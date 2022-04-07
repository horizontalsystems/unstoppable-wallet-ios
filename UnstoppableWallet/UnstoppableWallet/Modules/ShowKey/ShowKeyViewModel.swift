import RxSwift
import RxRelay
import RxCocoa

class ShowKeyViewModel {
    private let service: ShowKeyService
    private let disposeBag = DisposeBag()

    private let openUnlockRelay = PublishRelay<()>()
    private let showKeyRelay = PublishRelay<()>()
    private let copyRelay = PublishRelay<String>()

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

    var copySignal: Signal<String> {
        copyRelay.asSignal()
    }

    var words: [String] {
        service.words
    }

    var passphrase: String? {
        service.salt.isEmpty ? nil : service.salt
    }

    var evmPrivateKey: String? {
        service.ethereumPrivateKey
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

    func onCopyBitcoin(derivation: MnemonicDerivation) {
        if let json = try? service.bitcoinPublicKeys(derivation: derivation) {
            copyRelay.accept(json)
        }
    }

    func onCopyBitcoinCash(coinType: BitcoinCashCoinType) {
        if let json = try? service.bitcoinCashPublicKeys(coinType: coinType) {
            copyRelay.accept(json)
        }
    }

    func onCopyLitecoin(derivation: MnemonicDerivation) {
        if let json = try? service.litecoinPublicKeys(derivation: derivation) {
            copyRelay.accept(json)
        }
    }

    func onCopyDash() {
        if let json = try? service.dashPublicKeys() {
            copyRelay.accept(json)
        }
    }

}
