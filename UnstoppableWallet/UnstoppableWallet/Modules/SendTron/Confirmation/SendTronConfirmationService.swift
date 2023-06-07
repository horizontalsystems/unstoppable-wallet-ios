import Foundation
import RxSwift
import RxCocoa
import TronKit
import BigInt
import HsExtensions
import Combine

class SendTronConfirmationService {
    private var tasks = Set<AnyTask>()

    private let trxDecimals = Decimal(1_000_000)
    private let feeService: SendFeeService
    private let contract: Contract
    private let tronKitWrapper: TronKitWrapper
    private let evmLabelManager: EvmLabelManager

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    let feeStateRelay = BehaviorRelay<DataStatus<Decimal>>(value: .loading)
    var feeState: DataStatus<Decimal> = .loading {
        didSet {
            if !feeState.equalTo(oldValue) {
                feeStateRelay.accept(feeState)
            }
        }
    }

    private(set) var dataState: DataState

    private let sendStateRelay = PublishRelay<SendState>()
    private(set) var sendState: SendState = .idle {
        didSet {
            sendStateRelay.accept(sendState)
        }
    }

    init(contract: Contract, tronKitWrapper: TronKitWrapper, feeService: SendFeeService, evmLabelManager: EvmLabelManager) {
        self.contract = contract
        self.tronKitWrapper = tronKitWrapper
        self.feeService = feeService
        self.evmLabelManager = evmLabelManager

        let tronKit = tronKitWrapper.tronKit

        dataState = DataState(
            contract: contract,
            decoration: tronKit.decorate(contract: contract)
        )

        feeService.feeValueService = self
        syncFees()
    }

    private var tronKit: TronKit.Kit {
        tronKitWrapper.tronKit
    }

    private func syncFees() {
        Task { [weak self, tronKit, contract] in
            let fees: [Fee]

            do {
                fees = try await tronKit.estimateFee(contract: contract)
            } catch {
                self?.feeState = .failed(error)
                self?.state = .notReady(errors: [error])
                return
            }

            self?.handleFees(fees: fees)
        }.store(in: &tasks)
    }

    private func handleFees(fees: [Fee]) {
        var totalFees = 0
        for fee in fees {
            switch fee {
            case .bandwidth(let points, let price):
                totalFees += points * price
            case .energy(let required, let price):
                totalFees += required * price
            case .accountActivation(let amount):
                totalFees += amount
            }
        }

        feeState = .completed(Decimal(totalFees) / trxDecimals)

        var totalAmount = totalFees
        if let transfer = contract as? TransferContract {
            totalAmount += transfer.amount
        }

        if tronKit.trxBalance < totalAmount {
            state = .notReady(errors: [TransactionError.insufficientBalance(balance: tronKit.trxBalance)])
            return
        }

        state = .ready(fees: fees)
    }

}

extension SendTronConfirmationService: ISendXFeeValueService {

    var feeStateObservable: Observable<DataStatus<Decimal>> {
        feeStateRelay.asObservable()
    }


}

extension SendTronConfirmationService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var sendStateObservable: Observable<SendState> {
        sendStateRelay.asObservable()
    }

    func send() {
        guard case .ready = state, case let .completed(fee) = feeState else {
            return
        }

        sendState = .sending

        let feeLimit = NSDecimalNumber(decimal: fee * trxDecimals).intValue

        Task { [weak self, tronKitWrapper, contract] in
            do {
                try await tronKitWrapper.send(contract: contract, feeLimit: feeLimit)
                self?.sendState = .sent
            } catch {
                self?.sendState = .failed(error: error)
            }
        }.store(in: &tasks)
    }

}

extension SendTronConfirmationService {

    enum State {
        case ready(fees: [Fee])
        case notReady(errors: [Error])
    }

    struct DataState {
        let contract: Contract?
        var decoration: TransactionDecoration?
    }

    enum SendState {
        case idle
        case sending
        case sent
        case failed(error: Error)
    }

    enum TransactionError: Error {
        case insufficientBalance(balance: BigUInt)
    }

}
