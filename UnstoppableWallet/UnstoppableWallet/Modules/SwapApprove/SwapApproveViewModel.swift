import Foundation
import RxCocoa
import RxSwift
import EthereumKit

class SwapApproveViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapApproveService

    private var approveAllowedRelay = BehaviorRelay<Bool>(value: false)
    private var approveSuccessRelay = PublishRelay<Void>()
    private var errorRelay = PublishRelay<Error>()

    let feePresenter: FeePresenter

    init(service: SwapApproveService, feePresenter: FeePresenter) {
        self.service = service
        self.feePresenter = feePresenter

        subscribe(disposeBag, service.approveState) { [weak self] approveState in self?.handle(approveState: approveState) }
    }

    private func handle(approveState: SwapApproveModule.ApproveState) {
        if case .approveAllowed = approveState {
            approveAllowedRelay.accept(true)
        } else {
            approveAllowedRelay.accept(false)
        }

        if case .success = approveState {
            approveSuccessRelay.accept(())
        }

        if case let .error(error) = approveState {
            errorRelay.accept(error)
        }
    }

}

extension SwapApproveViewModel {

    func onTapApprove() {
        service.approve()
    }

}

extension SwapApproveViewModel {

    public var coinAmount: String? {
        let coinValue = CoinValue(coin: service.coin, value: service.amount)
        return ValueFormatter.instance.format(coinValue: coinValue)
    }

    public var coinTitle: String {
        service.coin.title
    }

    public var approveAllowed: Driver<Bool> {
        approveAllowedRelay.asDriver()
    }

    public var approveSuccess: Signal<Void> {
        approveSuccessRelay.asSignal()
    }

    public var error: Signal<String> {
        errorRelay.asSignal().map({ $0.convertedError.smartDescription })
    }

}
