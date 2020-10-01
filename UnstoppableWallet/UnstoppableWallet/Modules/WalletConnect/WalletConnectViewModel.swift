import RxSwift
import RxRelay
import RxCocoa

class WalletConnectViewModel {
    let service: WalletConnectService

    private let openScreenRelay = PublishRelay<Screen>()
    private let finishRelay = PublishRelay<Void>()

    init(service: WalletConnectService) {
        self.service = service
    }

}

extension WalletConnectViewModel {

    var initialScreen: Screen {
        if !service.isEthereumKitReady {
            return .noEthereumKit
        }

        if service.isClientReady {
            return .main
        }

        return .scanQrCode
    }

    var openScreenSignal: Signal<Screen> {
        openScreenRelay.asSignal()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func onScan(string: String) {
        do {
            try service.initInteractor(uri: string)
            openScreenRelay.accept(.initialConnect)
        } catch {
            openScreenRelay.accept(.error(error))
        }
    }

    func onFinish() {
        finishRelay.accept(())
    }

}

extension WalletConnectViewModel {

    enum Screen {
        case noEthereumKit
        case scanQrCode
        case error(Error)
        case initialConnect
        case main
    }

}
