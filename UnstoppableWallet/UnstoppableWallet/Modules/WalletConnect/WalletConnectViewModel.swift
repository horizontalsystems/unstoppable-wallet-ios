import RxSwift
import RxRelay
import RxCocoa

class WalletConnectViewModel {
    private let service: WalletConnectService

    init(service: WalletConnectService) {
        self.service = service
    }

}

extension WalletConnectViewModel {

    var initialScreen: InitialScreen {
        .scanQrCode
    }

    var scanQrViewModel: WalletConnectScanQrViewModel {
        WalletConnectScanQrViewModel(service: service)
    }

    var initialConnectViewModel: WalletConnectInitialConnectViewModel {
        WalletConnectInitialConnectViewModel(service: service)
    }

    var mainViewModel: WalletConnectMainViewModel {
        WalletConnectMainViewModel(service: service)
    }

}

extension WalletConnectViewModel {

    enum InitialScreen {
        case scanQrCode
        case main
    }

}
