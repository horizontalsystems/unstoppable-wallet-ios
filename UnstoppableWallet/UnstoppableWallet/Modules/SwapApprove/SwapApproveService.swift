import Foundation
import RxCocoa
import RxSwift
import EthereumKit
import Erc20Kit
import BigInt

class SwapApproveService {
    private let disposeBag = DisposeBag()

    private let erc20Kit: Erc20Kit.Kit
    private(set) var amount: BigUInt?
    private let spenderAddress: EthereumKit.Address
    private let allowance: BigUInt

    private(set) var state: State = .approveNotAllowed(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }
    private let stateRelay = BehaviorRelay<State>(value: .approveNotAllowed(errors: []))

    init(erc20Kit: Erc20Kit.Kit, amount: BigUInt, spenderAddress: EthereumKit.Address, allowance: BigUInt) {
        self.erc20Kit = erc20Kit
        self.amount = amount
        self.spenderAddress = spenderAddress
        self.allowance = allowance

        syncState()
    }

    private func syncState() {
        guard let amount = amount else {
            state = .approveNotAllowed(errors: [])
            return
        }

        var errors = [Error]()

        if allowance >= amount && amount > 0 {   // 0 amount is used for USDT to drop existing allowance
            errors.append(TransactionAmountError.alreadyApproved)
        }

        if errors.isEmpty {
            let erc20KitTransactionData = erc20Kit.approveTransactionData(spenderAddress: spenderAddress, amount: amount)
            let transactionData = TransactionData(
                    to: erc20KitTransactionData.to,
                    value: erc20KitTransactionData.value,
                    input: erc20KitTransactionData.input
            )

            state = .approveAllowed(transactionData: transactionData)
        } else {
            state = .approveNotAllowed(errors: errors)
        }
    }

}

extension SwapApproveService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func set(amount: BigUInt?) {
        self.amount = amount

        syncState()
    }

}

extension SwapApproveService {

    enum State {
        case approveNotAllowed(errors: [Error])
        case approveAllowed(transactionData: TransactionData)
    }

    enum TransactionAmountError: Error {
        case alreadyApproved
    }

}
