import RxSwift
import RxCocoa
import EthereumKit
import CoinKit

class SendEvmViewModel {
    private let service: SendEvmService
    private let disposeBag = DisposeBag()

    private let proceedEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let amountCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let proceedRelay = PublishRelay<TransactionData>()

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

    var proceedSignal: Signal<TransactionData> {
        proceedRelay.asSignal()
    }

    var coin: Coin {
        service.sendCoin
    }

    func didTapProceed() {
        guard case .ready(let transactionData) = service.state else {
            return
        }

        proceedRelay.accept(transactionData)
    }

}
