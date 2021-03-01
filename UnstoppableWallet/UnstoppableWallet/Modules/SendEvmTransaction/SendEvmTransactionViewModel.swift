import Foundation
import RxSwift
import RxCocoa

class SendEvmTransactionViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendEvmTransactionService
    private let coinService: CoinService

    let viewItems: [ViewItem]

    private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    private let sendingRelay = PublishRelay<()>()
    private let sendSuccessRelay = PublishRelay<Data>()
    private let sendFailedRelay = PublishRelay<String>()

    init(service: SendEvmTransactionService, coinService: CoinService) {
        self.service = service
        self.coinService = coinService

        viewItems = [
            .to(value: service.toAddress.eip55),
            .amount(value: coinService.coinValue(value: service.amount).formattedString),
            .input(value: service.inputData.toHexString())
        ]

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.sendStateObservable) { [weak self] in self?.sync(sendState: $0) }

        sync(state: service.state)
        sync(sendState: service.sendState)
    }

    private func sync(state: SendEvmTransactionService.State) {
        if case .ready = state {
            sendEnabledRelay.accept(true)
        } else {
            sendEnabledRelay.accept(false)
        }

        if case .notReady(let errors) = state {
            errorRelay.accept(errors.first.map { convert(error: $0) })
        } else {
            errorRelay.accept(nil)
        }
    }

    private func sync(sendState: SendEvmTransactionService.SendState) {
        switch sendState {
        case .idle: ()
        case .sending: sendingRelay.accept(())
        case .sent(let transactionHash): sendSuccessRelay.accept(transactionHash)
        case .failed(let error): sendFailedRelay.accept(error.convertedError.smartDescription)
        }
    }

    private func convert(error: Error) -> String {
        if case WalletConnectSendEthereumTransactionRequestService.TransactionError.insufficientBalance(let requiredBalance) = error {
            let amountData = coinService.amountData(value: requiredBalance)
            return "ethereum_transaction.error.insufficient_balance".localized(amountData.formattedString)
        }

        if case AppError.ethereum(let reason) = error.convertedError {
            switch reason {
            case .insufficientBalanceWithFee, .executionReverted: return "ethereum_transaction.error.insufficient_balance_with_fee".localized(coinService.coin.code)
            default: ()
            }
        }

        return error.convertedError.smartDescription
    }

}

extension SendEvmTransactionViewModel {

    var sendEnabledDriver: Driver<Bool> {
        sendEnabledRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var sendingSignal: Signal<()> {
        sendingRelay.asSignal()
    }

    var sendSuccessSignal: Signal<Data> {
        sendSuccessRelay.asSignal()
    }

    var sendFailedSignal: Signal<String> {
        sendFailedRelay.asSignal()
    }

    func send() {
        service.send()
    }

}

extension SendEvmTransactionViewModel {

    enum ViewItem {
        case to(value: String)
        case amount(value: String)
        case input(value: String)
    }

}
