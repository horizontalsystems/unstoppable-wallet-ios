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

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: ProFeaturesYakAuthorizationService.State) {
        switch state {
        case .loading:
            showHudRelay.accept(true)
        case .idle:
            showHudRelay.accept(false)
        case .failed(let error):
            showHudRelay.accept(false)
        case .receivedMessage(let message):
            showHudRelay.accept(false)
        case .receivedSessionKey(let sessionKey):
            showHudRelay.accept(false)
        }
    }

}

extension ProFeaturesYakAuthorizationViewModel {

        var showHudDriver: Driver<Bool> {
            showHudRelay.asDriver()
        }

        var showSignMessageDriver: Driver<String> {
            showSignMessageRelay.asDriver()
        }

        var showLockInfoDriver: Driver<()> {
            showLockInfoRelay.asDriver()
        }

}
