import RxSwift
import RxRelay
import RxCocoa

class PublicKeysViewModel {
    private let service: PublicKeysService

    private let copyRelay = PublishRelay<String>()

    init(service: PublicKeysService) {
        self.service = service
    }

}

extension PublicKeysViewModel {

    var copySignal: Signal<String> {
        copyRelay.asSignal()
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
