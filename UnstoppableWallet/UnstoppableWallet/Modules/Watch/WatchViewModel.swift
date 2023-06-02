import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol IWatchSubViewModel: AnyObject {
    var watchEnabled: Bool { get }
    var watchEnabledObservable: Observable<Bool> { get }
    var domainObservable: Observable<String?> { get }
    func resolve() -> AccountType?
}

class WatchViewModel {
    private let service: WatchService
    private let tronService: WatchTronService
    private let evmAddressViewModel: IWatchSubViewModel
    private let tronAddressViewModel: IWatchSubViewModel
    private let publicKeyViewModel: IWatchSubViewModel
    private var disposeBag = DisposeBag()

    private let watchTypeRelay = BehaviorRelay<WatchModule.WatchType>(value: .evmAddress)
    private let watchEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let nameRelay = PublishRelay<String>()
    private let proceedRelay = PublishRelay<(WatchModule.WatchType, AccountType, String)>()

    init(service: WatchService, tronService: WatchTronService, evmAddressViewModel: IWatchSubViewModel, tronAddressViewModel: IWatchSubViewModel, publicKeyViewModel: IWatchSubViewModel) {
        self.service = service
        self.tronService = tronService
        self.evmAddressViewModel = evmAddressViewModel
        self.tronAddressViewModel = tronAddressViewModel
        self.publicKeyViewModel = publicKeyViewModel

        syncSubViewModel()
    }

    private var subViewModel: IWatchSubViewModel {
        switch watchTypeRelay.value {
        case .evmAddress: return evmAddressViewModel
        case .tronAddress: return tronAddressViewModel
        case .publicKey: return publicKeyViewModel
        }
    }

    private func syncSubViewModel() {
        disposeBag = DisposeBag()
        sync(watchEnabled: subViewModel.watchEnabled)
        subscribe(disposeBag, subViewModel.watchEnabledObservable) { [weak self] in self?.sync(watchEnabled: $0) }
        subscribe(disposeBag, subViewModel.domainObservable) { [weak self] in self?.sync(domain: $0) }
    }

    private func sync(watchEnabled: Bool) {
        watchEnabledRelay.accept(watchEnabled)
    }

    private func sync(domain: String?) {
        if let domain = domain, service.name == nil {
            service.set(name: domain)
            nameRelay.accept(domain)
        }
    }

}

extension WatchViewModel {

    var watchTypeDriver: Driver<WatchModule.WatchType> {
        watchTypeRelay.asDriver()
    }

    var watchEnabledDriver: Driver<Bool> {
        watchEnabledRelay.asDriver()
    }

    var proceedSignal: Signal<(WatchModule.WatchType, AccountType, String)> {
        proceedRelay.asSignal()
    }

    var defaultName: String {
        service.defaultAccountName
    }

    var nameSignal: Signal<String> {
        nameRelay.asSignal()
    }

    var hasNextPage: Bool {
        watchTypeRelay.value == .tronAddress
    }

    func onChange(name: String) {
        service.set(name: name)
    }

    func onSelect(watchType: WatchModule.WatchType) {
        guard watchTypeRelay.value != watchType else {
            return
        }

        watchTypeRelay.accept(watchType)
        syncSubViewModel()
    }

    func onTapNext() {
        if let accountType = subViewModel.resolve() {
            let watchType = watchTypeRelay.value
            if watchType == .tronAddress {
                tronService.enableWatch(accountType: accountType, accountName: service.resolvedName)
            }

            proceedRelay.accept((watchType, accountType, service.resolvedName))
        }
    }

}
