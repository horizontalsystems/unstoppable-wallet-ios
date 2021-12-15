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
        subscribe(disposeBag, service.amountCautionObservable) { [weak self] in self?.sync(amountCaution: $0) }

        sync(state: service.state)
    }

    private func sync(state: SendEvmService.State) {
        if case .ready = state {
            proceedEnabledRelay.accept(true)
        } else {
            proceedEnabledRelay.accept(false)
        }
    }

    private func sync(amountCaution: (error: Error?, warning: SendEvmService.AmountWarning?)) {
        var caution: Caution? = nil

        if let error = amountCaution.error {
            caution = Caution(text: error.smartDescription, type: .error)
        } else if let warning = amountCaution.warning {
            switch warning {
            case .coinNeededForFee: caution = Caution(text: "send.amount_warning.coin_needed_for_fee".localized(service.sendPlatformCoin.code), type: .warning)
            }
        }

        amountCautionRelay.accept(caution)
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
