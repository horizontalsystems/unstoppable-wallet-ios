import Foundation
import RxSwift
import RxRelay
import RxCocoa

class WatchPublicKeyViewModel {
    private let service: WatchPublicKeyService

    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)

    init(service: WatchPublicKeyService) {
        self.service = service
    }

}

extension WatchPublicKeyViewModel {

    var cautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    func onChange(text: String) {
        service.set(text: text)
        cautionRelay.accept(nil)
    }

}

extension WatchPublicKeyViewModel: IWatchSubViewModel {

    var watchEnabled: Bool {
        service.state.watchEnabled
    }

    var watchEnabledObservable: Observable<Bool> {
        service.stateObservable.map { $0.watchEnabled }
    }

    var domainObservable: Observable<String?> {
        Observable.just(nil)
    }

    func resolve() -> AccountType? {
        cautionRelay.accept(nil)

        do {
            let accountType = try service.resolve()
            return accountType
        } catch {
            cautionRelay.accept(Caution(text: "watch_address.public_key.invalid_key".localized, type: .error))
            return nil
        }
    }

}
