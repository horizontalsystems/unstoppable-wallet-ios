import RxSwift
import RxRelay
import RxCocoa

class EthereumFeeViewModel {
    private let customFeeUnit = "gwei"

    private let service: IEvmTransactionFeeService
    private let coinService: CoinService

    private let disposeBag = DisposeBag()

    private let estimatedFeeStatusRelay = BehaviorRelay<String?>(value: nil)
    private let feeStatusRelay = BehaviorRelay<String?>(value: "")
    private let priorityRelay = BehaviorRelay<String>(value: "")
    private let openSelectPriorityRelay = PublishRelay<[SendPriorityViewItem]>()
    private let feeSliderRelay = BehaviorRelay<SendFeeSliderViewItem?>(value: nil)
    private let warningOfStuckRelay = BehaviorRelay<Bool>(value: false)

    init(service: IEvmTransactionFeeService, coinService: CoinService) {
        self.service = service
        self.coinService = coinService

        sync(transactionStatus: service.transactionStatus)
        sync(gasPriceType: service.gasPriceType)

        subscribe(disposeBag, service.transactionStatusObservable) { [weak self] in self?.sync(transactionStatus: $0) }
        subscribe(disposeBag, service.gasPriceTypeObservable) { [weak self] in self?.sync(gasPriceType: $0) }
        subscribe(disposeBag, service.warningOfStuckObservable) { [weak self] in self?.sync(warningOfStuck: $0) }
    }

    private func sync(transactionStatus: DataStatus<EvmTransactionService.Transaction>) {
        let estimatedFeeStatus = service.hasEstimatedFee ? estimatedFeeStatus(transactionStatus: transactionStatus) : nil

        estimatedFeeStatusRelay.accept(estimatedFeeStatus)
        feeStatusRelay.accept(feeStatus(transactionStatus: transactionStatus))
    }

    private func sync(warningOfStuck: Bool) {
        warningOfStuckRelay.accept(warningOfStuck)
    }

    private func estimatedFeeStatus(transactionStatus: DataStatus<EvmTransactionService.Transaction>) -> String {
        switch transactionStatus {
        case .loading:
            return "action.loading".localized
        case .failed:
            return "n/a".localized
        case .completed(let transaction):
            return coinService.amountData(value: transaction.gasData.estimatedFee).formattedString
        }
    }

    private func feeStatus(transactionStatus: DataStatus<EvmTransactionService.Transaction>) -> String {
        switch transactionStatus {
        case .loading:
            return "action.loading".localized
        case .failed:
            return "n/a".localized
        case .completed(let transaction):
            return coinService.amountData(value: transaction.gasData.fee).formattedString
        }
    }

    private func sync(gasPriceType: EvmTransactionService.GasPriceType) {
        priorityRelay.accept(priority(gasPriceType: gasPriceType).description)

        switch gasPriceType {
        case .recommended:
            feeSliderRelay.accept(nil)
        case .custom(let gasPrice):
            guard feeSliderRelay.value == nil else {
                return
            }

            feeSliderRelay.accept(SendFeeSliderViewItem(initialValue: gwei(wei: gasPrice), range: gwei(range: service.customFeeRange), unit: customFeeUnit))
        }
    }

    private func priority(gasPriceType: EvmTransactionService.GasPriceType) -> Priority {
        switch gasPriceType {
        case .recommended: return .recommended
        case .custom: return .custom
        }
    }

    private func gwei(wei: Int) -> Int {
        wei / 1_000_000_000
    }

    private func gwei(range: ClosedRange<Int>) -> ClosedRange<Int> {
        gwei(wei: range.lowerBound)...gwei(wei: range.upperBound)
    }

    private func wei(gwei: Int) -> Int {
        gwei * 1_000_000_000
    }

}

extension EthereumFeeViewModel {

    var estimatedFeeDriver: Driver<String?> {
        estimatedFeeStatusRelay.asDriver()
    }

    var feeDriver: Driver<String?> {
        feeStatusRelay.asDriver()
    }

}

extension EthereumFeeViewModel: ISendFeePriorityViewModel {

    var priorityDriver: Driver<String> {
        priorityRelay.asDriver()
    }

    var openSelectPrioritySignal: Signal<[SendPriorityViewItem]> {
        openSelectPriorityRelay.asSignal()
    }

    var feeSliderDriver: Driver<SendFeeSliderViewItem?> {
        feeSliderRelay.asDriver()
    }

    var warningOfStuckDriver: Driver<Bool> {
        warningOfStuckRelay.asDriver()
    }

    func openSelectPriority() {
        let currentPriority = priority(gasPriceType: service.gasPriceType)

        let viewItems = Priority.allCases.map { priority in
            SendPriorityViewItem(title: priority.description, selected: priority == currentPriority)
        }

        openSelectPriorityRelay.accept(viewItems)
    }

    func selectPriority(index: Int) {
        let selectedPriority = Priority.allCases[index]
        let currentPriority = priority(gasPriceType: service.gasPriceType)

        guard selectedPriority != currentPriority else {
            return
        }

        switch selectedPriority {
        case .recommended:
            service.set(gasPriceType: .recommended)
        case .custom:
            let gasPrice: Int = {
                if case .completed(let transaction) = service.transactionStatus {
                    return transaction.gasData.gasPrice
                } else {
                    return service.customFeeRange.lowerBound
                }
            }()

            service.set(gasPriceType: .custom(gasPrice: gasPrice))
        }
    }

    func changeCustomPriority(value: Int) {
        service.set(gasPriceType: .custom(gasPrice: wei(gwei: value)))
    }

}

extension EthereumFeeViewModel {

    enum Priority: CaseIterable, CustomStringConvertible {
        case recommended
        case custom

        var description: String {
            switch self {
            case .recommended: return "send.tx_speed_recommended".localized
            case .custom: return "send.tx_speed_custom".localized
            }
        }
    }

}
