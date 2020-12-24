import RxSwift
import RxRelay
import RxCocoa

class WalletConnectSendEthereumTransactionRequestViewModel {
    private let service: WalletConnectSendEthereumTransactionRequestService
    private let coinService: CoinService

    private let disposeBag = DisposeBag()

    let amountData: AmountData
    let viewItems: [WalletConnectRequestViewItem]

    private let approveEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let rejectEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)
    private let sendingRelay = BehaviorRelay<Bool>(value: false)
    private let approveRelay = PublishRelay<Data>()

    init(service: WalletConnectSendEthereumTransactionRequestService, coinService: CoinService) {
        self.service = service
        self.coinService = coinService

        amountData = coinService.amountData(value: service.transactionData.value)

        viewItems = [
            .to(value: service.transactionData.to.eip55),
            .input(value: service.transactionData.input.toHexString())
        ]

        service.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] state in
                    self?.sync(state: state)
                })
                .disposed(by: disposeBag)

        sync(state: service.state)
    }

    private func sync(state: WalletConnectSendEthereumTransactionRequestService.State) {
        if case .sent(let transactionHash) = state {
            approveRelay.accept(transactionHash)
            return
        }

        approveEnabledRelay.accept(state == .ready)
        rejectEnabledRelay.accept(state != .sending)

        if case .notReady(let errors) = state {
            errorRelay.accept(errors.first.map { convert(error: $0) })
        } else {
            errorRelay.accept(nil)
        }

        sendingRelay.accept(state == .sending)
    }

    private func convert(error: Error) -> String {
        if case WalletConnectSendEthereumTransactionRequestService.TransactionError.insufficientBalance(let requiredBalance) = error {
            let amountData = coinService.amountData(value: requiredBalance)
            return "ethereum_transaction.error.insufficient_balance".localized(amountData.formattedString)
        }

        return error.convertedError.smartDescription
    }

}

extension WalletConnectSendEthereumTransactionRequestViewModel {

    var approveEnabledDriver: Driver<Bool> {
        approveEnabledRelay.asDriver()
    }

    var rejectEnabledDriver: Driver<Bool> {
        rejectEnabledRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var sendingDriver: Driver<Bool> {
        sendingRelay.asDriver()
    }

    var approveSignal: Signal<Data> {
        approveRelay.asSignal()
    }

    func approve() {
        service.send()
    }

}
