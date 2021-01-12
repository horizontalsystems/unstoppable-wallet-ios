import Foundation
import RxCocoa
import RxSwift
import EthereumKit
import Erc20Kit
import BigInt

class SwapApproveService {
    private let disposeBag = DisposeBag()

    private let transactionService: EthereumTransactionService
    private let erc20Kit: Erc20Kit.Kit
    private let ethereumKit: EthereumKit.Kit

    private(set) var amount: BigUInt?
    private let spenderAddress: EthereumKit.Address
    private let allowance: BigUInt

    private(set) var state: State = .approveNotAllowed(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }
    private let stateRelay = BehaviorRelay<State>(value: .approveNotAllowed(errors: []))

    init(transactionService: EthereumTransactionService, erc20Kit: Erc20Kit.Kit, ethereumKit: EthereumKit.Kit, amount: BigUInt, spenderAddress: EthereumKit.Address, allowance: BigUInt) {
        self.transactionService = transactionService
        self.erc20Kit = erc20Kit
        self.ethereumKit = ethereumKit

        self.amount = amount
        self.spenderAddress = spenderAddress
        self.allowance = allowance

        transactionService.transactionStatusObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncState()
                })
                .disposed(by: disposeBag)

        syncTransactionData(amount: amount)
    }

    private func syncTransactionData(amount: BigUInt) {
        let erc20KitTransactionData = erc20Kit.approveTransactionData(spenderAddress: spenderAddress, amount: amount)
        let transactionData = TransactionData(
                to: erc20KitTransactionData.to,
                value: erc20KitTransactionData.value,
                input: erc20KitTransactionData.input
        )

        transactionService.set(transactionData: transactionData)
    }

    private var ethereumBalance: BigUInt {
        ethereumKit.accountState?.balance ?? 0
    }

    private func syncState() {
        guard let amount = amount else {
            state = .approveNotAllowed(errors: [])
            return
        }

        var errors = [Error]()
        var loading = false

        if allowance >= amount && amount > 0 {   // 0 amount is used for USDT to drop existing allowance
            errors.append(TransactionAmountError.alreadyApproved)
        }

        switch transactionService.transactionStatus {
        case .loading:
            loading = true
        case .failed(let error):
            errors.append(error)
        case .completed(let transaction):
            if transaction.totalAmount > ethereumBalance {
                errors.append(TransactionEthereumAmountError.insufficientBalance(requiredBalance: transaction.totalAmount))
            }
        }

        if errors.isEmpty && !loading {
            state = .approveAllowed
        } else {
            state = .approveNotAllowed(errors: errors)
        }
    }

}

extension SwapApproveService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func approve() {
        guard case .completed(let transaction) = transactionService.transactionStatus else {
            return
        }

        state = .loading

        ethereumKit.sendSingle(
                        address: transaction.data.to,
                        value: transaction.data.value,
                        transactionInput: transaction.data.input,
                        gasPrice: transaction.gasData.gasPrice,
                        gasLimit: transaction.gasData.gasLimit
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] transactionWithInternal in
                    self?.state = .success
                }, onError: { [weak self] error in
                    self?.state = .error(error: error)
                })
                .disposed(by: disposeBag)
    }

    func set(amount: BigUInt?) {
        self.amount = amount

        if let amount = amount {
            syncTransactionData(amount: amount)
        } else {
            syncState()
        }
    }

}

extension SwapApproveService {

    enum State {
        case approveNotAllowed(errors: [Error])
        case approveAllowed
        case loading
        case success
        case error(error: Error)
    }

    enum TransactionAmountError: Error {
        case alreadyApproved
    }

    enum TransactionEthereumAmountError: Error {
        case insufficientBalance(requiredBalance: BigUInt)
    }

}
