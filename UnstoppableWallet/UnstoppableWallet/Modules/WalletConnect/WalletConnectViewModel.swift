import WalletConnect
import RxSwift
import RxCocoa

class WalletConnectViewModel {
    private let service: WalletConnectService

    init(service: WalletConnectService) {
        self.service = service
    }

}

extension WalletConnectViewModel {

    var scanQrPresenter: WalletConnectScanQrPresenter {
        WalletConnectScanQrPresenter(service: service)
    }

    var mainPresenter: WalletConnectMainPresenter {
        WalletConnectMainPresenter(service: service)
    }

    func requestPresenter(requestId: Int) -> WalletConnectRequestPresenter {
        WalletConnectRequestPresenter(service: service, requestId: requestId)
    }

    var initialScreen: InitialScreen {
        if !service.isEthereumKitReady {
            return .noEthereumKit
        }

        if service.state == .idle {
            return .scanQrCode
        }

        return .main
    }

}

extension WalletConnectViewModel {

    enum InitialScreen {
        case noEthereumKit
        case scanQrCode
        case main
    }

}
