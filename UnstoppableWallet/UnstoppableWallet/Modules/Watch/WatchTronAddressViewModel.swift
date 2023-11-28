import Foundation
import RxCocoa
import RxRelay
import RxSwift

class WatchTronAddressViewModel {
    private let service: WatchTronAddressService

    init(service: WatchTronAddressService) {
        self.service = service
    }
}

extension WatchTronAddressViewModel: IWatchSubViewModel {
    var watchEnabled: Bool {
        service.state.watchEnabled
    }

    var watchEnabledObservable: Observable<Bool> {
        service.stateObservable.map(\.watchEnabled)
    }

    var domainObservable: Observable<String?> {
        service.stateObservable.map(\.domain)
    }

    func resolve() -> AccountType? {
        service.resolve()
    }
}
