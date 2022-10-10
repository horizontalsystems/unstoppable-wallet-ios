import Foundation
import UIKit
import WalletConnectV1

protocol IWalletConnectInteractorDelegate: AnyObject {
    func didUpdate(state: WalletConnectInteractor.State)
    func didRequestSession(peerId: String, peerMeta: WCPeerMeta, chainId: Int?)
    func didKillSession()
    func didRequestSendEthereumTransaction(id: Int, transaction: WCEthereumTransaction)
    func didRequestSignEthereumTransaction(id: Int, transaction: WCEthereumTransaction)
    func didRequestSign(id: Int, payload: WCEthereumSignPayload)
    func didReceive(error: Error)
}

extension IWalletConnectInteractorDelegate {

    func didRequestSession(peerId: String, peerMeta: WalletConnectV1.WCPeerMeta, chainId: Int?) {}
    func didKillSession() {}
    func didRequestSendEthereumTransaction(id: Int, transaction: WalletConnectV1.WCEthereumTransaction) {}
    func didRequestSignEthereumTransaction(id: Int, transaction: WalletConnectV1.WCEthereumTransaction) {}
    func didRequestSign(id: Int, payload: WalletConnectV1.WCEthereumSignPayload) {}
    func didReceive(error: Error) {}

}

class WalletConnectInteractor {
    private static let clientMeta = WCPeerMeta(name: "Unstoppable Wallet", url: "https://unstoppable.money")

    weak var delegate: IWalletConnectInteractorDelegate?

    private let interactor: WCInteractor

    private(set) var state: State = .disconnected {
        didSet {
            delegate?.didUpdate(state: state)
        }
    }

    init(session: WCSession, remotePeerId: String? = nil) {
        interactor = WCInteractor(session: session, meta: Self.clientMeta, uuid: UIDevice.current.identifierForVendor ?? UUID(), peerId: remotePeerId)

        interactor.onSessionRequest = { [weak self] (id, requestParam) in
            self?.delegate?.didRequestSession(peerId: requestParam.peerId, peerMeta: requestParam.peerMeta, chainId: requestParam.chainId)
        }

        interactor.onSessionKill = { [weak self] in
            self?.delegate?.didKillSession()
        }

        interactor.onError = { [weak self] error in
            self?.onError(error: error)
        }

        interactor.onDisconnect = { [weak self] error in
            self?.state = .disconnected
        }

        interactor.eth.onTransaction = { [weak self] id, event, transaction in
            switch event {
            case .ethSendTransaction:
                self?.delegate?.didRequestSendEthereumTransaction(id: Int(id), transaction: transaction)
            case .ethSignTransaction:
                self?.delegate?.didRequestSignEthereumTransaction(id: Int(id), transaction: transaction)
            default:
                self?.rejectWithNotSupported(id: id)
            }
        }

        interactor.eth.onSign = { [weak self] id, payload in
            self?.delegate?.didRequestSign(id: Int(id), payload: payload)
        }

        interactor.bnb.onSign = { [weak self] id, _ in
            self?.rejectWithNotSupported(id: id)
        }

        interactor.trust.onTransactionSign = { [weak self] id, _ in
            self?.rejectWithNotSupported(id: id)
        }

        interactor.trust.onGetAccounts = { [weak self] id in
            self?.rejectWithNotSupported(id: id)
        }
    }

    convenience init(uri: String) throws {
        guard let session = WCSession.from(string: uri) else {
            throw SessionError.invalidUri
        }

        self.init(session: session)
    }

    private func onError(error: Error) {
        delegate?.didReceive(error: error)
    }

    private func rejectWithNotSupported(id: Int64) {
        interactor.rejectRequest(id: id, message: "Not supported yet").cauterize()
    }

}

extension WalletConnectInteractor {

    var session: WCSession {
        interactor.session
    }

    func connect() {
        state = .connecting

        interactor.connect().done { [weak self] connected in
            self?.state = .connected
        }.catch { [weak self] error in
            print("Connect Error: \(error)")
            self?.state = .disconnected
        }
    }

    func approveSession(address: String, chainId: Int) {
        interactor.approveSession(accounts: [address], chainId: chainId).cauterize()
    }

    func rejectSession(message: String) {
        interactor.rejectSession(message).cauterize()
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

    public enum State {
        case connected
        case connecting
        case disconnected
    }

    enum SessionError: LocalizedError {
        case invalidUri

        var errorDescription: String? {
            "wallet_connect.error.invalid_url".localized
        }
    }

}
