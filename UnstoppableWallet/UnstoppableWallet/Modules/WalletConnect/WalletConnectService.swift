import EthereumKit
import WalletConnect
import RxSwift
import RxRelay
import CurrencyKit
import BigInt

class WalletConnectService {
    private var ethereumKit: EthereumKit.Kit?
    private let appConfigProvider: IAppConfigProvider
    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager
    private let sessionStore: WalletConnectSessionStore

    private let disposeBag = DisposeBag()

    private var interactor: WalletConnectInteractor?
    private var remotePeerData: PeerData?

    private var stateRelay = PublishRelay<State>()
    private var requestRelay = PublishRelay<Int>()

    private var pendingRequests = [Request]()

    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(ethereumKitManager: EthereumKitManager, appConfigProvider: IAppConfigProvider, currencyKit: ICurrencyKit, rateManager: IRateManager, sessionStore: WalletConnectSessionStore) {
        ethereumKit = ethereumKitManager.ethereumKit
        self.appConfigProvider = appConfigProvider
        self.currencyKit = currencyKit
        self.rateManager = rateManager
        self.sessionStore = sessionStore

        if let storeItem = sessionStore.storedItem {
            remotePeerData = PeerData(id: storeItem.peerId, meta: storeItem.peerMeta)

            interactor = WalletConnectInteractor(session: storeItem.session, remotePeerId: storeItem.peerId)
            interactor?.delegate = self
            interactor?.connect()

            state = .connecting
        }
    }

    private func ethereumTransaction(transaction: WCEthereumTransaction) throws -> EthereumTransaction {
        guard let to = transaction.to else {
            throw TransactionError.invalidRecipient
        }

        guard let gasLimitString = transaction.gas ?? transaction.gasLimit, let gasLimit = Int(gasLimitString.replacingOccurrences(of: "0x", with: ""), radix: 16) else {
            throw TransactionError.invalidGasLimit
        }

        guard let valueString = transaction.value, let value = BigUInt(valueString.replacingOccurrences(of: "0x", with: ""), radix: 16) else {
            throw TransactionError.invalidValue
        }

        guard let data = Data(hex: transaction.data) else {
            throw TransactionError.invalidData
        }

        return EthereumTransaction(
                from: try Address(hex: transaction.from),
                to: try Address(hex: to),
                nonce: transaction.nonce.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                gasPrice: transaction.gasPrice.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                gasLimit: gasLimit,
                value: value,
                data: data
        )
    }

}

extension WalletConnectService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var requestObservable: Observable<Int> {
        requestRelay.asObservable()
    }

    var isEthereumKitReady: Bool {
        ethereumKit != nil
    }

    var remotePeerMeta: WCPeerMeta? {
        remotePeerData?.meta
    }

    var ethereumCoin: Coin {
        appConfigProvider.ethereumCoin
    }

    var ethereumRate: CurrencyValue? {
        let baseCurrency = currencyKit.baseCurrency

        return rateManager.marketInfo(coinCode: ethereumCoin.code, currencyCode: baseCurrency.code).map { marketInfo in
            CurrencyValue(currency: baseCurrency, value: marketInfo.rate)
        }
    }

    func request(id: Int) -> Request? {
        pendingRequests.first { $0.id == id }
    }

    func connect(uri: String) throws {
        interactor = try WalletConnectInteractor(uri: uri)
        interactor?.delegate = self
        interactor?.connect()

        state = .connecting
    }

    func approveSession() {
        guard let ethereumKit = ethereumKit, let interactor = interactor else {
            return
        }

        interactor.approveSession(address: ethereumKit.address.eip55, chainId: ethereumKit.networkType.chainId)

        if let peerData = remotePeerData {
            sessionStore.store(session: interactor.session, peerId: peerData.id, peerMeta: peerData.meta)
        }

        state = .ready
    }

    func rejectSession() {
        guard let interactor = interactor else {
            return
        }

        interactor.rejectSession()

        state = .completed
    }

    func approveRequest(id: Int) {
        guard let index = pendingRequests.firstIndex(where: { $0.id == id }) else {
            print("APPROVE: request not found")
            return
        }

        let request = pendingRequests.remove(at: index)

        switch request.type {
        case .sendEthereumTransaction(let transaction):
            interactor?.rejectRequest(id: id, message: "Not implemented yet")

//            ethereumKit?.sendSingle(
//                            address: transaction.to,
//                            value: transaction.value,
//                            transactionInput: transaction.data,
//                            gasPrice: 50_000_000_000,
//                            gasLimit: transaction.gasLimit,
//                            nonce: transaction.nonce
//                    )
//                    .subscribe(onSuccess: { [weak self] transactionWithInternal in
//                        self?.interactor?.approveRequest(id: id, result: transactionWithInternal.transaction.hash.toHexString())
//                    }, onError: { [weak self] error in
//                        self?.interactor?.rejectRequest(id: id, message: error.smartDescription)
//                    })
//                    .disposed(by: disposeBag)
        case .signEthereumTransaction(let transaction):
            // todo
            interactor?.rejectRequest(id: id, message: "Not implemented yet")
        }
    }

    func rejectRequest(id: Int) {
        guard let index = pendingRequests.firstIndex(where: { $0.id == id }) else {
            return
        }

        pendingRequests.remove(at: index)

        interactor?.rejectRequest(id: id, message: "Rejected by user")
    }

    func killSession() {
        guard let interactor = interactor else {
            return
        }

        interactor.killSession()
    }

}

extension WalletConnectService: IWalletConnectInteractorDelegate {

    func didConnect() {
        if remotePeerData != nil {
            state = .ready
        }
    }

    func didRequestSession(peerId: String, peerMeta: WCPeerMeta) {
        remotePeerData = PeerData(id: peerId, meta: peerMeta)

        state = .waitingForApproveSession
    }

    func didKillSession() {
        sessionStore.clear()

        state = .completed
    }

    func didRequestEthereumTransaction(id: Int, event: WCEvent, transaction: WCEthereumTransaction) {
        do {
            let transaction = try ethereumTransaction(transaction: transaction)

            let requestType: Request.RequestType

            switch event {
            case .ethSendTransaction: requestType = .sendEthereumTransaction(transaction: transaction)
            case .ethSignTransaction: requestType = .signEthereumTransaction(transaction: transaction)
            default: throw TransactionError.unsupportedRequestType
            }

            let request = Request(id: id, type: requestType)

            pendingRequests.append(request)
            requestRelay.accept(request.id)
        } catch {
            interactor?.rejectRequest(id: id, message: error.smartDescription)
        }

    }

}

extension WalletConnectService {

    enum State {
        case idle
        case connecting
        case waitingForApproveSession
        case ready
        case completed
    }

    struct PeerData {
        let id: String
        let meta: WCPeerMeta
    }

    struct Request {
        let id: Int
        let type: RequestType

        enum RequestType {
            case sendEthereumTransaction(transaction: EthereumTransaction)
            case signEthereumTransaction(transaction: EthereumTransaction)
        }
    }

    struct EthereumTransaction {
        let from: Address
        let to: Address
        let nonce: Int?
        let gasPrice: Int?
        let gasLimit: Int
        let value: BigUInt
        let data: Data
    }

    enum TransactionError: Error {
        case unsupportedRequestType
        case invalidRecipient
        case invalidGasLimit
        case invalidValue
        case invalidData
    }

}
