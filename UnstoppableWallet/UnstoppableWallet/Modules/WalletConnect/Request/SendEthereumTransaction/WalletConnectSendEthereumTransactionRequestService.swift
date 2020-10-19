import EthereumKit
import RxSwift
import RxRelay
import CurrencyKit
import BigInt

class WalletConnectSendEthereumTransactionRequestService {
    private let transactionService: EthereumTransactionService
    private var ethereumKit: EthereumKit.Kit

    let transactionData: EthereumTransactionService.TransactionData

    private(set) var state: State = .notReady(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }
    private let stateRelay = PublishRelay<State>()

    private let disposeBag = DisposeBag()

    init(transaction: WalletConnectTransaction, transactionService: EthereumTransactionService, ethereumKit: EthereumKit.Kit) {
        self.transactionService = transactionService
        self.ethereumKit = ethereumKit

        transactionData = EthereumTransactionService.TransactionData(to: transaction.to, value: transaction.value, input: transaction.data)

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
        ethereumKit.balance ?? 0
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

}

extension WalletConnectSendEthereumTransactionRequestService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension WalletConnectSendEthereumTransactionRequestService {

    enum State {
        case ready
        case notReady(errors: [Error])
    }

    enum TransactionError: Error {
        case insufficientBalance(requiredBalance: BigUInt)
    }

}
