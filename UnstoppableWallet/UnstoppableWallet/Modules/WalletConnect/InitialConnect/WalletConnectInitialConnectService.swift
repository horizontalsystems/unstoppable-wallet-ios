import EthereumKit

class WalletConnectInitialConnectService {
    private let interactor: WalletConnectInteractor
    private let ethereumKit: Kit

    private init(interactor: WalletConnectInteractor, ethereumKit: Kit) {
        self.interactor = interactor
        self.ethereumKit = ethereumKit
    }

}

extension WalletConnectInitialConnectService: IWalletConnectInteractorDelegate {

    func didConnect() {
    }

    func didRequestSession() {
    }

}

extension WalletConnectInitialConnectService {

    static func instance(interactor: WalletConnectInteractor, ethereumKit: Kit) -> WalletConnectInitialConnectService {
        let service = WalletConnectInitialConnectService(interactor: interactor, ethereumKit: ethereumKit)
        interactor.delegate = service
        return service
    }

}
