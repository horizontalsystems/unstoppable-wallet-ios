import Foundation
import RxCocoa
import RxSwift
import EthereumKit

class SwapApproveViewModel {
    private let service: SwapApproveService

    private let disposeBag = DisposeBag()
    private let feeModule: IFeeModule

    private var approveAllowedRelay = BehaviorRelay<Bool>(value: false)
    private var feeRelay = BehaviorRelay<String>(value: "")
    private var feeLoadingRelay = BehaviorRelay<Bool>(value: true)

    private var approveSuccessRelay = PublishRelay<>()
    private var errorRelay = PublishRelay<Error>()

    init(service: SwapApproveService, feeModule: IFeeModule) {
        self.service = service
        self.feeModule = feeModule

        subscribe(disposeBag, service.approveState) { [weak self] approveState in self?.handle(approveState: approveState) }
        subscribe(disposeBag, service.fee) { [weak self] feeState in self?.handle(feeState: feeState) }
    }

    private func handle(approveState: ApproveState) {
        switch approveState {
        case .approveNotAllowed:
            approveAllowedRelay.accept(false)
        case .approveAllowed:
            approveAllowedRelay.accept(true)
        case .loading:
            ()
        case .success():
            approveSuccessRelay.accept()
        case .error(let error):
            errorRelay.accept(error)
        }
    }

    private func handle(feeState: DataState<Int>) {
        switch feeState {
        case .success(result: let feeInt):
            if let feeRate = service.feeRate {
                let feeDecimal = Decimal(feeInt) * Decimal(feeRate.feeRate(priority: SwapApproveService.feePriority)) / pow(10, EthereumAdapter.decimal)

                feeModule.viewItem(coin: service.coin, fee: feeDecimal, reversed: false).value.flatMap { feeValue in
                    feeRelay.accept(feeValue)
                }
            }

        case .error(error: let error):
            errorRelay.accept(error)

        case .loading:
            feeLoadingRelay.accept(true)
        }
    }

}

extension SwapApproveViewModel {

    func onTapApprove() {
        handle(approveState: .success(transactionHash: "lala"))
//        service.approve()
    }

}

extension SwapApproveViewModel {

    public var coinAmount: String {
        "\(service.amount.description) \(service.coin.code)"
    }

    public var coinTitle: String {
        service.coin.title
    }

    public var transactionSpeed: String {
        SwapApproveService.feePriority.title
    }

    public var approveAllowed: Driver<Bool> {
        approveAllowedRelay.asDriver()
    }

    public var fee: Driver<String> {
        feeRelay.asDriver()
    }

    public var feeLoading: Driver<Bool> {
        feeLoadingRelay.asDriver()
    }

    public var approveSuccess: Signal<> {
        approveSuccessRelay.asSignal()
    }

    public var error: Signal<Error> {
        errorRelay.asSignal()
    }

}
