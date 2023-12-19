import RxCocoa
import RxSwift

class WalletConnectScanQrViewModel {
    private let openErrorRelay = PublishRelay<Error>()

    init() {}
}

extension WalletConnectScanQrViewModel {
    func didScan(string _: String) {}
}
