import Foundation
import RxCocoa
import RxSwift
import EthereumKit
import BigInt

class SwapApproveViewModel {
    private let maxCoinDecimal = 8
    private let disposeBag = DisposeBag()

    private let service: SwapApproveService
    private let coinService: CoinService
    private let ethereumCoinService: CoinService

    private var inputFieldValueRelay = BehaviorRelay<String?>(value: nil)
    private var approveAllowedRelay = BehaviorRelay<Bool>(value: false)
    private var approveSuccessRelay = PublishRelay<Void>()
    private var approveErrorRelay = PublishRelay<String>()

    private let amountErrorRelay = BehaviorRelay<String?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    private let decimalParser: IAmountDecimalParser

    init(service: SwapApproveService, coinService: CoinService, ethereumCoinService: CoinService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.coinService = coinService
        self.ethereumCoinService = ethereumCoinService
        self.decimalParser = decimalParser

        subscribe(disposeBag, service.stateObservable) { [weak self] approveState in self?.handle(approveState: approveState) }
        inputFieldValueRelay.accept(service.amount.map { coinService.monetaryValue(value: $0).description })
    }

    private func handle(approveState: SwapApproveService.State) {
        if case .success = approveState {
            approveSuccessRelay.accept(())
            return
        }

        if case let .error(error) = approveState {
            approveErrorRelay.accept(error.convertedError.smartDescription)
            return
        }

        if case .approveAllowed = approveState {
            approveAllowedRelay.accept(true)
        } else {
            approveAllowedRelay.accept(false)
        }

        if case .approveNotAllowed(var errors) = approveState {
            if let balanceErrorIndex = errors.firstIndex(where: { $0 is SwapApproveService.TransactionAmountError }) {
                amountErrorRelay.accept(convert(error: errors.remove(at: balanceErrorIndex)))
            } else {
                amountErrorRelay.accept(nil)
            }

            errorRelay.accept(errors.first.map { convert(error: $0) })
        }
    }

    private func convert(error: Error) -> String {
        if case SwapApproveService.TransactionAmountError.alreadyApproved = error {
            return "swap.approve.amount_error.already_approved".localized()
        }

        if case SwapApproveService.TransactionEthereumAmountError.insufficientBalance(let requiredBalance) = error {
            let amountData = ethereumCoinService.amountData(value: requiredBalance)
            return "ethereum_transaction.error.insufficient_balance".localized(amountData.formattedString)
        }

        if case EthereumKit.Kit.EstimatedLimitError.insufficientBalance = error {
            return "ethereum_transaction.error.insufficient_balance_with_fee".localized
        }

        return error.smartDescription
    }

}

extension SwapApproveViewModel: IVerifiedInputViewModel {

    var inputFieldValueDriver: Driver<String?> {
        inputFieldValueRelay.asDriver()
    }

    func inputFieldDidChange(text: String?) {
        let amount = text
                .flatMap { Decimal(string: $0) }
                .map { coinService.fractionalMonetaryValue(value: $0) }

        service.set(amount: amount)
    }

    func inputFieldIsValid(text: String) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: text) else {
            return false
        }

        // TODO: Decimal count check must be implemented in coinService and used in other places too
        return amount.decimalCount <= min(coinService.coin.decimal, maxCoinDecimal)
    }

    var inputFieldCautionDriver: Driver<Caution?> {
        amountErrorRelay.asDriver().map { errorString in
            errorString.map { Caution(text: $0, type: .error) }
        }
    }

}

extension SwapApproveViewModel {

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var approveAllowedDriver: Driver<Bool> {
        approveAllowedRelay.asDriver()
    }

    var approveSuccessSignal: Signal<Void> {
        approveSuccessRelay.asSignal()
    }

    var approveErrorSignal: Signal<String> {
        approveErrorRelay.asSignal()
    }

    func approve() {
        service.approve()
    }

}
