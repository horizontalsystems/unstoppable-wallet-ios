import BigInt
import Eip20Kit
import EvmKit
import Foundation
import RxCocoa
import RxSwift

class SwapApproveService {
    private let disposeBag = DisposeBag()

    private let eip20Kit: Eip20Kit.Kit
    private(set) var amount: BigUInt?
    private let spenderAddress: EvmKit.Address
    private let allowance: BigUInt

    private(set) var state: State = .approveNotAllowed(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let stateRelay = BehaviorRelay<State>(value: .approveNotAllowed(errors: []))

    init(eip20Kit: Eip20Kit.Kit, amount: BigUInt, spenderAddress: EvmKit.Address, allowance: BigUInt) {
        self.eip20Kit = eip20Kit
        self.amount = amount
        self.spenderAddress = spenderAddress
        self.allowance = allowance

        syncState()
    }

    private func syncState() {
        guard let amount else {
            state = .approveNotAllowed(errors: [])
            return
        }

        var errors = [Error]()

        if allowance >= amount, amount > 0 { // 0 amount is used for USDT to drop existing allowance
            errors.append(TransactionAmountError.alreadyApproved)
        }

        if errors.isEmpty {
            let eip20KitTransactionData = eip20Kit.approveTransactionData(spenderAddress: spenderAddress, amount: amount)
            state = .approveAllowed(transactionData: eip20KitTransactionData)
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
