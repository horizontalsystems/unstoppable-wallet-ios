import RxSwift
import RxCocoa
import RxRelay

class ProFeaturesYakAuthorizationViewModel {
    private let disposeBag = DisposeBag()

    private let service: ProFeaturesYakAuthorizationService

    private let showHudRelay = PublishRelay<Bool>()
    private let showSignMessageRelay = PublishRelay<String>()
    private let showLockInfoRelay = PublishRelay<()>()

    init(service: ProFeaturesYakAuthorizationService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in
            self?.sync(state: $0)
        }
    }

    private func sync(state: ProFeaturesYakAuthorizationService.State) {
        switch state {
        case .loading:
            showHudRelay.accept(true)
        case .idle:
            showHudRelay.accept(false)
        case .failed:
            showHudRelay.accept(false)
        case .receivedMessage:
            showHudRelay.accept(false)
            showSignMessageRelay.accept("dfsdkjfh")
        case .receivedSessionKey:
            showHudRelay.accept(false)
        }
    }

}

extension ProFeaturesYakAuthorizationViewModel {

    var title: String {
        "pro_features.authorize.wallet_passes.title".localized
    }

    var subtitle: String {
        "pro_features.authorize.wallet_passes.subtitle".localized
    }

    var showHudSignal: Signal<Bool> {
        showHudRelay.asSignal()
    }

    var showSignMessageSignal: Signal<String> {
        showSignMessageRelay.asSignal()
    }

    var showLockInfoSignal: Signal<()> {
        showLockInfoRelay.asSignal()
    }

    func authorize() {
        service.authenticate()
    }

    func activate(message: String) {
        service.activate()
    }

}
