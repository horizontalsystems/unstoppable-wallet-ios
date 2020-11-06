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

    private var approveAllowedRelay = BehaviorRelay<Bool>(value: false)
    private var approveSuccessRelay = PublishRelay<Void>()
    private var approveErrorRelay = PublishRelay<String>()

    private let balanceErrorRelay = BehaviorRelay<String?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    private let decimalParser: ISendAmountDecimalParser

    init(service: SwapApproveService, coinService: CoinService, ethereumCoinService: CoinService, decimalParser: ISendAmountDecimalParser) {
        self.service = service
        self.coinService = coinService
        self.ethereumCoinService = ethereumCoinService
        self.decimalParser = decimalParser

        subscribe(disposeBag, service.stateObservable) { [weak self] approveState in self?.handle(approveState: approveState) }
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
                balanceErrorRelay.accept(convert(error: errors.remove(at: balanceErrorIndex)))
            } else {
                balanceErrorRelay.accept(nil)
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

        return error.smartDescription
    }

}

extension SwapApproveViewModel: IVerifiedInputViewModel {

    var inputFieldInitialValue: String? {
        coinService.coinValue(value: service.amount).value.description
    }

    func inputFieldDidChange(text: String) {
        guard let amount = Decimal(string: text) else {
            balanceErrorRelay.accept(nil)
            return
        }

        service.set(amount: coinService.bigUInt(value: amount))
    }

    func inputFieldIsValid(text: String) -> Bool {
        guard !text.isEmpty else {
            return true
        }

        guard let value = decimalParser.parseAnyDecimal(from: text) else {
            return false
        }

        // TODO: Decimal count check must be implemented in coinService and used in other places too
        return value.decimalCount <= min(coinService.coin.decimal, maxCoinDecimal)
    }

    var inputFieldCautionDriver: Driver<Caution?> {
        balanceErrorRelay.asDriver().map { errorString in
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
