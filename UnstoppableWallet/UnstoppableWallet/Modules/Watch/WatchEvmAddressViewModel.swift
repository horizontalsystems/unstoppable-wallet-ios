import Foundation
import RxCocoa
import RxRelay
import RxSwift

class WatchEvmAddressViewModel {
    private let service: WatchEvmAddressService

    init(service: WatchEvmAddressService) {
        self.service = service
    }
}

extension WatchEvmAddressViewModel: IWatchSubViewModel {
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
