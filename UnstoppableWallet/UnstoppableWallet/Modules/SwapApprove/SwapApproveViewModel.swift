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
        handle(approveState: .success)
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

    public var approveAllowed: Driver<Bool> {
        approveAllowedRelay.asDriver()
    }

    public var approveSuccess: Signal<Void> {
        approveSuccessRelay.asSignal()
    }

    public var error: Signal<String> {
        errorRelay.asSignal().map({ $0.smartDescription })
    }

}
