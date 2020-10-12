import WalletConnect

protocol IWalletConnectInteractorDelegate: AnyObject {
    func didConnect()
    func didRequestSession(peerId: String, peerMeta: WCPeerMeta)
    func didKillSession()
    func didRequestEthereumTransaction(id: Int, event: WCEvent, transaction: WCEthereumTransaction)
}

class WalletConnectInteractor {
    private static let clientMeta = WCPeerMeta(name: "Unstoppable Wallet", url: "https://unstoppable.money")

    weak var delegate: IWalletConnectInteractorDelegate?

    private let interactor: WCInteractor

    init(session: WCSession, remotePeerId: String? = nil) {
        interactor = WCInteractor(session: session, meta: Self.clientMeta, uuid: UIDevice.current.identifierForVendor ?? UUID(), peerId: remotePeerId)

        interactor.onSessionRequest = { [weak self] (id, requestParam) in
            self?.delegate?.didRequestSession(peerId: requestParam.peerId, peerMeta: requestParam.peerMeta)
        }

        interactor.onSessionKill = { [weak self] in
            self?.delegate?.didKillSession()
        }

        interactor.onError = { [weak self] error in
            self?.onError(error: error)
        }

        interactor.onDisconnect = { [weak self] error in
            self?.onDisconnect(error: error)
        }

        interactor.eth.onTransaction = { [weak self] id, event, transaction in
            self?.delegate?.didRequestEthereumTransaction(id: Int(id), event: event, transaction: transaction)
        }
    }

    convenience init(uri: String) throws {
        guard let session = WCSession.from(string: uri) else {
            throw SessionError.invalidUri
        }

        self.init(session: session)
    }

    private func onDisconnect(error: Error?) {
        print("Interactor Disconnect: \(error)")
    }

    private func onError(error: Error) {
        print("Interactor Error: \(error)")
    }

}

extension WalletConnectInteractor {

    var session: WCSession {
        interactor.session
    }

    func connect() {
        interactor.connect().done { [weak self] connected in
            print("Connected")
            self?.delegate?.didConnect()
        }.catch { [weak self] error in
            print("Error: \(error)")
        }
    }

    func approveSession(address: String, chainId: Int) {
        interactor.approveSession(accounts: [address], chainId: chainId).cauterize()
    }

    func rejectSession() {
        interactor.rejectSession().cauterize()
    }

    func killSession() {
        interactor.killSession().cauterize()
    }

    func approveRequest<T: Codable>(id: Int, result: T) {
        interactor.approveRequest(id: Int64(id), result: result).cauterize()
    }

    func rejectRequest(id: Int, message: String) {
        interactor.rejectRequest(id: Int64(id), message: message).cauterize()
    }

}

extension WalletConnectInteractor {

    enum SessionError: LocalizedError {
        case invalidUri

        var errorDescription: String? {
            "wallet_connect.error.invalid_url".localized
        }
    }

}
