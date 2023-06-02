import Foundation
import RxSwift
import RxRelay
import RxCocoa

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
        service.stateObservable.map { $0.watchEnabled }
    }

    var domainObservable: Observable<String?> {
        service.stateObservable.map { $0.domain }
    }

    func resolve() -> AccountType? {
        service.resolve()
    }

}
