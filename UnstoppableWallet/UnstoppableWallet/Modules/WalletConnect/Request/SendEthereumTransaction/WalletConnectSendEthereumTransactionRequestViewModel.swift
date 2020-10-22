import RxSwift
import RxRelay
import RxCocoa

class WalletConnectSendEthereumTransactionRequestViewModel {
    private let service: WalletConnectSendEthereumTransactionRequestService
    private let coinService: EthereumCoinService

    private let disposeBag = DisposeBag()

    let amountData: AmountData
    let viewItems: [WalletConnectRequestViewItem]

    private let approveEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let rejectEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let errorsRelay = BehaviorRelay<Error?>(value: nil)
    private let sendingRelay = BehaviorRelay<Bool>(value: false)
    private let approveRelay = PublishRelay<Data>()

    init(service: WalletConnectSendEthereumTransactionRequestService, coinService: EthereumCoinService) {
        self.service = service
        self.coinService = coinService

        amountData = coinService.amountData(value: service.transactionData.value ?? 0)

        var viewItems = [WalletConnectRequestViewItem]()

        if let to = service.transactionData.to {
            viewItems.append(.to(value: to.eip55))
        }

        viewItems.append(.input(value: service.transactionData.input.toHexString()))

        self.viewItems = viewItems

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
            errorsRelay.accept(convert(error: errors.first))
        } else {
            errorsRelay.accept(nil)
        }

        sendingRelay.accept(state == .sending)
    }

    private func convert(error: Error?) -> Error? {
        if let transactionError = error as? WalletConnectSendEthereumTransactionRequestService.TransactionError {
            switch transactionError {
            case .insufficientBalance(let requiredBalance):
                return SendError.insufficientBalance(requiredBalance: coinService.amountData(value: requiredBalance))
            }
        }

        return error
    }

}

extension WalletConnectSendEthereumTransactionRequestViewModel {

    var approveEnabledDriver: Driver<Bool> {
        approveEnabledRelay.asDriver()
    }

    var rejectEnabledDriver: Driver<Bool> {
        rejectEnabledRelay.asDriver()
    }

    var errorsDriver: Driver<Error?> {
        errorsRelay.asDriver()
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

extension WalletConnectSendEthereumTransactionRequestViewModel {

    enum SendError: LocalizedError {
        case insufficientBalance(requiredBalance: AmountData)

        public var errorDescription: String? {
            switch self {
            case .insufficientBalance(let requiredBalance):
                return "ethereum_transaction.error.insufficient_balance".localized(requiredBalance.formattedString)
            }
        }
    }

}
