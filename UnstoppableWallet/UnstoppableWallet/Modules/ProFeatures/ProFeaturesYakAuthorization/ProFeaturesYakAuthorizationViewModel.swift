import RxSwift
import RxCocoa
import RxRelay

class ProFeaturesYakAuthorizationViewModel {
    private let disposeBag = DisposeBag()

    private let service: ProFeaturesYakAuthorizationService

    private let showHudRelay = PublishRelay<Bool>()
    private let showSignMessageRelay = PublishRelay<()>()
    private let showLockInfoRelay = PublishRelay<()>()
    private let showErrorRelay = PublishRelay<String>()
    private let showSuccessSignedRelay = PublishRelay<()>()

    init(service: ProFeaturesYakAuthorizationService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in
            self?.sync(state: $0)
        }
        subscribe(disposeBag, service.activationErrorObservable) { [weak self] in
            self?.sync(error: $0)
        }
    }

    private func sync(state: ProFeaturesYakAuthorizationService.State) {
        switch state {
        case .idle:
            showHudRelay.accept(false)
        case .loading:
            showHudRelay.accept(true)
        case .noYakNft:
            service.reset()
            showLockInfoRelay.accept(())
        case .failure(let error):
            service.reset()
            showErrorRelay.accept(error.smartDescription)
        case .receivedMessage:
            showHudRelay.accept(false)
            showSignMessageRelay.accept(())
        case .receivedSessionKey:
            service.reset()
            showSuccessSignedRelay.accept(())
        }
    }

    private func sync(error: Error?) {
        guard let error = error else {
            return
        }

        let errorString = "pro_features.activate.invalid_sign".localized + "\n" + error.convertedError.smartDescription
        showErrorRelay.accept(errorString)
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

    var showSignMessageSignal: Signal<()> {
        showSignMessageRelay.asSignal()
    }

    var showLockInfoSignal: Signal<()> {
        showLockInfoRelay.asSignal()
    }

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
    }

    var showSuccessSignedSignal: Signal<()> {
        showSuccessSignedRelay.asSignal()
    }

    func authorize() {
        service.authenticate()
    }

    func activate() {
        service.activate()
    }

    func dismissSign() {
        service.reset()
    }

}
