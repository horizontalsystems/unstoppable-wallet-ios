import Foundation
import RxSwift
import RxRelay
import RxCocoa

class WatchAddressViewModel {
    private let service: WatchAddressService
    private let disposeBag = DisposeBag()

    private let watchEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let finishRelay = PublishRelay<Void>()

    init(service: WatchAddressService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: WatchAddressService.State) {
        switch state {
        case .ready:
            watchEnabledRelay.accept(true)
        case .notReady:
            watchEnabledRelay.accept(false)
        }
    }

}

extension WatchAddressViewModel {

    var watchEnabledDriver: Driver<Bool> {
        watchEnabledRelay.asDriver()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func onTapWatch() {
        do {
            try service.watch()
            finishRelay.accept(())
        } catch {
            // do nothing, watch button is already disabled for this case
        }
    }

}
