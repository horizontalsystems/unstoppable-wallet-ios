import EthereumKit
import RxSwift
import RxRelay
import CurrencyKit
import BigInt

class WalletConnectSendEthereumTransactionRequestService {
    private let request: WalletConnectSendEthereumTransactionRequest
    private let baseService: WalletConnectService
    private let transactionService: EvmTransactionService
    private var evmKit: EthereumKit.Kit

    let transactionData: TransactionData

    private(set) var state: State = .notReady(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }
    private let stateRelay = PublishRelay<State>()

    private let disposeBag = DisposeBag()

    init(request: WalletConnectSendEthereumTransactionRequest, baseService: WalletConnectService, transactionService: EvmTransactionService, evmKit: EthereumKit.Kit) {
        self.request = request
        self.baseService = baseService
        self.transactionService = transactionService
        self.evmKit = evmKit

        let transaction = request.transaction

        transactionData = TransactionData(to: transaction.to, value: transaction.value, input: transaction.data)

        if let gasPrice = transaction.gasPrice {
            transactionService.set(gasPriceType: .custom(gasPrice: gasPrice))
        }

        transactionService.transactionStatusObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.syncState()
                })
                .disposed(by: disposeBag)

        transactionService.set(transactionData: transactionData)
    }

    private var ethereumBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func syncState() {
        switch transactionService.transactionStatus {
        case .loading:
            state = .notReady(errors: [])
        case .failed(let error):
            state = .notReady(errors: [error])
        case .completed(let transaction):
            if transaction.totalAmount > ethereumBalance {
                state = .notReady(errors: [TransactionError.insufficientBalance(requiredBalance: transaction.totalAmount)])
            } else {
                state = .ready
            }
        }
    }

    private func handleSent(transactionHash: Data) {
        baseService.approveRequest(id: request.id, result: transactionHash)
        state = .sent
    }

}

extension WalletConnectSendEthereumTransactionRequestService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func approve() {
        guard case .ready = state, case .completed(let transaction) = transactionService.transactionStatus else {
            return
        }

        state = .sending

        evmKit.sendSingle(
                transactionData: transactionData,
                gasPrice: transaction.gasData.gasPrice,
                gasLimit: transaction.gasData.gasLimit
        )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] fullTransaction in
                    self?.handleSent(transactionHash: fullTransaction.transaction.hash)
                }, onError: { error in
                    // todo
                })
                .disposed(by: disposeBag)
    }

    func reject() {
        baseService.rejectRequest(id: request.id)
    }

}

extension WalletConnectSendEthereumTransactionRequestService {

    enum State: Equatable {
        case ready
        case notReady(errors: [Error])
        case sending
        case sent

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.ready, .ready): return true
            case (.notReady, .notReady): return true
            case (.sending, .sending): return true
            case (.sent, .sent): return true
            default: return false
            }
        }
    }

    enum TransactionError: Error {
        case insufficientBalance(requiredBalance: BigUInt)
    }

}
