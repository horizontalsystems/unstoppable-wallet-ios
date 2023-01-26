import Foundation
import RxSwift
import RxRelay
import RxCocoa

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
        service.stateObservable.map { $0.watchEnabled }
    }

    var nameObservable: Observable<String?> {
        service.stateObservable.map { $0.name }
    }

    func resolve() -> AccountType? {
        service.resolve()
    }

}
