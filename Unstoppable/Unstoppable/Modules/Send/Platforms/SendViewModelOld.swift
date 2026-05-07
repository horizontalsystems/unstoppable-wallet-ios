import EvmKit
import MarketKit
import RxCocoa
import RxSwift

protocol ISendBaseService {
    var token: Token { get }
    var mode: PreSendViewModel.Mode { get }
    var state: SendBaseService.State { get }
    var stateObservable: Observable<SendBaseService.State> { get }
}

class SendViewModelOld {
    private let service: ISendBaseService
    private let disposeBag = DisposeBag()

    private let proceedEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let proceedRelay = PublishRelay<Void>()

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

extension SendViewModelOld {
    var proceedEnableDriver: Driver<Bool> {
        proceedEnabledRelay.asDriver()
    }

    var proceedSignal: Signal<Void> {
        proceedRelay.asSignal()
    }

    var token: Token {
        service.token
    }

    var title: String {
        switch service.mode {
        case .regular, .prefilled: return "send.title".localized(token.coin.code)
        case .predefined: return "donate.title".localized(token.coin.code)
        }
    }

    var showAddress: Bool {
        switch service.mode {
        case .regular, .prefilled: return true
        case .predefined: return false
        }
    }

    func didTapProceed() {
        guard case .ready = service.state else {
            return
        }

        proceedRelay.accept(())
    }
}
