import WalletConnectV1
import RxSwift
import RxCocoa

class WalletConnectViewModel {
    let service: WalletConnectService

    init(service: WalletConnectService) {
        self.service = service
    }

}

extension WalletConnectViewModel {

    var scanQrViewModel: WalletConnectScanQrViewModel {
        WalletConnectScanQrViewModel(service: service)
    }

    var mainViewModel: WalletConnectMainViewModel {
        WalletConnectMainViewModel(service: service)
    }

    var initialScreen: InitialScreen {
        if service.state == .idle {
            return .scanQrCode
        }

        return .main
    }

}

extension WalletConnectViewModel {

    enum InitialScreen {
        case scanQrCode
        case main
    }

}
