import WalletConnect

protocol IWalletConnectInteractorDelegate: AnyObject {
    func didConnect()
    func didRequestSession()
}

class WalletConnectInteractor {
    private static let clientMeta = WCPeerMeta(name: "Unstoppable Wallet", url: "https://unstoppable.money")

    weak var delegate: IWalletConnectInteractorDelegate?

    private let interactor: WCInteractor

    private init(session: WCSession) {
        interactor = WCInteractor(session: session, meta: Self.clientMeta, uuid: UIDevice.current.identifierForVendor ?? UUID())

        interactor.onSessionRequest = { [weak self] (id, requestParam) in
            self?.onSessionRequest(id: id, requestParam: requestParam)
        }

        interactor.onError = { [weak self] error in
            self?.onError(error: error)
        }

        interactor.onDisconnect = { [weak self] (error) in
            self?.onDisconnect(error: error)
        }
    }

    private func onSessionRequest(id: Int64, requestParam: WCSessionRequestParam) {
        print("Interactor Session Request: \(id)")
        print("Peer: \(requestParam.chainId ?? -1); \(requestParam.peerId); \(requestParam.peerMeta)")

        delegate?.didRequestSession()
    }

    private func onDisconnect(error: Error?) {
        print("Interactor Disconnect: \(error)")
    }

    private func onError(error: Error) {
        print("Interactor Error: \(error)")
    }

}

extension WalletConnectInteractor {

    func connect() {
        interactor.connect().done { [weak self] connected in
            print("Connected")
            self?.delegate?.didConnect()
        }.catch { [weak self] error in
            print("Error: \(error)")
        }
    }

}

extension WalletConnectInteractor {

    static func instance(uri: String) throws -> WalletConnectInteractor {
        guard let session = WCSession.from(string: uri) else {
            throw SessionError.invalidUri
        }

        return WalletConnectInteractor(session: session)
    }

    static func instance(session: WCSession) -> WalletConnectInteractor {
        WalletConnectInteractor(session: session)
    }

}

extension WalletConnectInteractor {

    enum SessionError: Error {
        case invalidUri
    }

}
