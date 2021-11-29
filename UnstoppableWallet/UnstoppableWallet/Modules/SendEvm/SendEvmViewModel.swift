import RxSwift
import RxCocoa
import EthereumKit
import MarketKit

class SendEvmViewModel {
    private let service: SendEvmService
    private let disposeBag = DisposeBag()

    private let proceedEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let amountCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let proceedRelay = PublishRelay<SendEvmData>()

    init(service: SendEvmService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.amountErrorObservable) { [weak self] in self?.sync(amountError: $0) }

        sync(state: service.state)
    }

    private func sync(state: SendEvmService.State) {
        if case .ready = state {
            proceedEnabledRelay.accept(true)
        } else {
            proceedEnabledRelay.accept(false)
        }
    }

    private func sync(amountError: Error?) {
        amountCautionRelay.accept(amountError.map { Caution(text: $0.smartDescription, type: .error) })
    }

}

extension SendEvmViewModel {

    var proceedEnableDriver: Driver<Bool> {
        proceedEnabledRelay.asDriver()
    }

    var amountCautionDriver: Driver<Caution?> {
        amountCautionRelay.asDriver()
    }

    var proceedSignal: Signal<SendEvmData> {
        proceedRelay.asSignal()
    }

    var platformCoin: PlatformCoin {
        service.sendPlatformCoin
    }

    func didTapProceed() {
        guard case .ready(let sendData) = service.state else {
            return
        }

        proceedRelay.accept(sendData)
    }

}

extension SendEvmService.AmountError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .insufficientBalance: return "send.amount_error.balance".localized
        default: return "\(self)"
        }
    }

}
