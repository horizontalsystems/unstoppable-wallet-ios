import Foundation
import RxCocoa
import RxSwift
import EthereumKit

class SwapApproveViewModel {
    static private let feePriority: FeeRatePriority = .high

    private let service: SwapApproveService
    private let feeModule: IFeeModule

    private let disposeBag = DisposeBag()

    private var viewItem: SwapApproveModule.ViewItem
    private var coin: Coin
    private var amount: Decimal
    private var spenderAddress: Address
    private var feeRate: FeeRate? = nil

    private var approveLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var approveSuccessRelay = BehaviorRelay<Bool>(value: false)
    private var approveErrorRelay = BehaviorRelay<Error?>(value: nil)

    private var feeRelay = BehaviorRelay<String?>(value: nil)
    private var feeErrorRelay = BehaviorRelay<Error?>(value: nil)
    private var feeLoadingRelay = BehaviorRelay<Bool>(value: false)

    init(service: SwapApproveService, feeModule: IFeeModule, coin: Coin, amount: Decimal, spenderAddress: Address) {
        self.service = service
        self.feeModule = feeModule
        self.viewItem = SwapApproveModule.ViewItem(coinCode: coin.code, amount: amount.description, transactionSpeed: SwapApproveViewModel.feePriority.title)
        self.coin = coin
        self.amount = amount
        self.spenderAddress = spenderAddress

        subscribe(disposeBag, service.approve) { [weak self] dataState in self?.handle(approveState: dataState) }
        subscribe(disposeBag, service.feeRate) { [weak self] feeRateState in self?.handle(feeRateState: feeRateState) }
        subscribe(disposeBag, service.fee) { [weak self] feeState in self?.handle(feeState: feeState) }

        service.fetchFeeRate()
    }

    private func handle(approveState: ApproveState) {
        if case .loading = approveState {
            approveLoadingRelay.accept(true)
        } else {
            approveLoadingRelay.accept(false)
        }

        switch approveState {
        case .success:
            approveSuccessRelay.accept(true)
        case .error(let error):
            approveErrorRelay.accept(error)
        case .idle, .loading: ()
        }
    }

    private func handle(feeRateState: DataState<FeeRate>) {
        switch feeRateState {
        case .success(result: let feeRate):
            self.feeRate = feeRate
            self.service.fetchFee(address: spenderAddress.hex, amount: amount, feeRate: feeRate.feeRate(priority: SwapApproveViewModel.feePriority))

        case .error(error: let error):
            self.feeErrorRelay.accept(error)

        case .loading:
            self.feeLoadingRelay.accept(true)
        }
    }

    private func handle(feeState: DataState<Int>) {
        switch feeState {
        case .success(result: let fee):
            if let feeRate = self.feeRate {
                let feeDecimal = Decimal(fee) * Decimal(feeRate.feeRate(priority: SwapApproveViewModel.feePriority)) / pow(10, EthereumAdapter.decimal)
                let feeValue = feeModule.viewItem(coin: coin, fee: feeDecimal, reversed: false).value
                self.feeRelay.accept(feeValue)
            }

        case .error(error: let error):
            self.feeErrorRelay.accept(error)

        case .loading:
            self.feeLoadingRelay.accept(true)
        }
    }

}

extension SwapApproveViewModel {

    func onTapApprove() {
        guard let gasLimit = feeRelay.value, let gasPrice = feeRate else {
            return
        }
        handle(approveState: .loading)
//        interactor.approve(spenderAddress: spenderAddress, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice.feeRate(priority: SwapApprovePresenter.feePriority))
    }

}

extension SwapApproveViewModel {

    public var viewItemDriver: Driver<SwapApproveModule.ViewItem> {
        Driver<SwapApproveModule.ViewItem>.just(viewItem)
    }

    public var approveLoading: Driver<Bool> {
        approveLoadingRelay.asDriver()
    }

    public var approveSuccess: Driver<Bool> {
        approveSuccessRelay.asDriver()
    }

    public var approveError: Driver<Error?> {
        approveErrorRelay.asDriver()
    }

    public var fee: Driver<String?> {
        feeRelay.asDriver()
    }

    public var feeLoading: Driver<Bool> {
        feeLoadingRelay.asDriver()
    }

    public var feeError: Driver<Error?> {
        feeErrorRelay.asDriver()
    }

}
