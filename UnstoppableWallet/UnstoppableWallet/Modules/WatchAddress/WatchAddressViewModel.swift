import Foundation
import RxSwift
import RxRelay
import RxCocoa

class WatchAddressViewModel {
    private let service: WatchAddressService
    private let disposeBag = DisposeBag()

    private let nameRelay = BehaviorRelay<String>(value: "")
    private let watchEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let finishRelay = PublishRelay<Void>()

    init(service: WatchAddressService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.nameObservable) { [weak self] in self?.sync(name: $0) }

        sync(state: service.state)
        sync(name: service.name)
    }

    private func sync(state: WatchAddressService.State) {
        switch state {
        case .ready:
            watchEnabledRelay.accept(true)
        case .notReady:
            watchEnabledRelay.accept(false)
        }
    }

    private func sync(name: String) {
        nameRelay.accept(name)
    }

}

extension WatchAddressViewModel {

    var nameDriver: Driver<String> {
        nameRelay.asDriver()
    }

    var watchEnabledDriver: Driver<Bool> {
        watchEnabledRelay.asDriver()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    var namePlaceholder: String {
        service.defaultName
    }

    func onChange(name: String?) {
        service.set(name: name ?? "")
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
