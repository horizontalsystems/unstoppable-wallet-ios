import EthereumKit
import RxSwift
import RxRelay
import CurrencyKit
import BigInt

class WalletConnectSendEthereumTransactionRequestService {
    private let transactionService: EthereumTransactionService
    private var ethereumKit: EthereumKit.Kit

    let transactionData: TransactionData

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
        ethereumKit.accountState?.balance ?? 0
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

    func send() {
        guard case .ready = state, case .completed(let transaction) = transactionService.transactionStatus else {
            return
        }

        state = .sending

        ethereumKit.sendSingle(
                transactionData: transactionData,
                gasPrice: transaction.gasData.gasPrice,
                gasLimit: transaction.gasData.gasLimit
        )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] fullTransaction in
                    self?.state = .sent(transactionHash: fullTransaction.transaction.hash)
                }, onError: { error in
                    // todo
                })
                .disposed(by: disposeBag)
    }

}

extension WalletConnectSendEthereumTransactionRequestService {

    enum State: Equatable {
        case ready
        case notReady(errors: [Error])
        case sending
        case sent(transactionHash: Data)

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
