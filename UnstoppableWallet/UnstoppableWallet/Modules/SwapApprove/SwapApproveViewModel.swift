import Foundation
import RxCocoa
import RxSwift
import EvmKit
import BigInt

class SwapApproveViewModel {
    private let maxCoinDecimals = 8
    private let disposeBag = DisposeBag()

    private let service: SwapApproveService
    private let coinService: CoinService

    private var approveAllowedRelay = BehaviorRelay<Bool>(value: false)
    private var proceedRelay = PublishRelay<TransactionData>()

    private let amountCautionRelay = BehaviorRelay<Caution?>(value: nil)

    private let decimalParser: AmountDecimalParser

    init(service: SwapApproveService, coinService: CoinService, decimalParser: AmountDecimalParser) {
        self.service = service
        self.coinService = coinService
        self.decimalParser = decimalParser

        service.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] approveState in
                    self?.handle(approveState: approveState)
                })
                .disposed(by: disposeBag)
    }

    private func handle(approveState: SwapApproveService.State) {
        if case .approveAllowed = approveState {
            approveAllowedRelay.accept(true)
        } else {
            approveAllowedRelay.accept(false)
        }

        var amountCaution: Caution?

        if case .approveNotAllowed(var errors) = approveState {
            if let balanceErrorIndex = errors.firstIndex(where: { $0 is SwapApproveService.TransactionAmountError }) {
                let errorString = convert(error: errors.remove(at: balanceErrorIndex))
                amountCaution = Caution(text: errorString, type: .error)
            }
        }

        amountCautionRelay.accept(amountCaution)
    }

    private func convert(error: Error) -> String {
        if case SwapApproveService.TransactionAmountError.alreadyApproved = error {
            return "swap.approve.amount_error.already_approved".localized()
        }

        return error.convertedError.smartDescription
    }

}

extension SwapApproveViewModel {

    var initialAmount: String? {
        service.amount.map { coinService.monetaryValue(value: $0).description }
    }

    var amountCautionDriver: Driver<Caution?> {
        amountCautionRelay.asDriver()
    }

    var approveAllowedDriver: Driver<Bool> {
        approveAllowedRelay.asDriver()
    }

    var proceedSignal: Signal<TransactionData> {
        proceedRelay.asSignal()
    }

    func isValid(amount: String) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: amount) else {
            return false
        }

        // TODO: Decimal count check must be implemented in coinService and used in other places too
        return amount.decimalCount <= min(coinService.token.decimals, maxCoinDecimals)
    }

    func onChange(amount: String?) {
        let amount = decimalParser.parseAnyDecimal(from: amount)
                .map { coinService.fractionalMonetaryValue(value: $0) }

        service.set(amount: amount)
    }

    func proceed() {
        guard case .approveAllowed(let transactionData) = service.state else {
            return
        }

        proceedRelay.accept(transactionData)
    }

}
