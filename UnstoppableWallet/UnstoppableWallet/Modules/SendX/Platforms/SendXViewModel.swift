import RxSwift
import RxCocoa
import EthereumKit
import MarketKit

protocol ISendBaseService {
    var platformCoin: PlatformCoin { get }
    var state: SendBaseService.State { get }
    var stateObservable: Observable<SendBaseService.State> { get }
}

class SendXViewModel {
    private let service: ISendBaseService
    private let disposeBag = DisposeBag()

    private let proceedEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let proceedRelay = PublishRelay<()>()

    private var firstLoaded: Bool = false

    init(service: ISendBaseService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: SendBaseService.State) {
        switch state {
        case .loading:
            if !firstLoaded {
                proceedEnabledRelay.accept(false)
            }
        case .ready:
            firstLoaded = true
            proceedEnabledRelay.accept(true)
        case .notReady:
            proceedEnabledRelay.accept(false)
        }
    }

}

extension SendXViewModel {

    var proceedEnableDriver: Driver<Bool> {
        proceedEnabledRelay.asDriver()
    }

    var proceedSignal: Signal<()> {
        proceedRelay.asSignal()
    }

    var platformCoin: PlatformCoin {
        service.platformCoin
    }

    func didTapProceed() {
        guard case .ready = service.state else {
            return
        }

        proceedRelay.accept(())
    }

}
