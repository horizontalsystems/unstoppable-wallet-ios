import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol IWatchSubViewModel: AnyObject {
    var watchEnabled: Bool { get }
    var watchEnabledObservable: Observable<Bool> { get }
    var nameObservable: Observable<String?> { get }
    func resolve() -> AccountType?
}

class WatchViewModel {
    private let service: WatchService
    private let evmAddressViewModel: IWatchSubViewModel
    private let publicKeyViewModel: IWatchSubViewModel
    private var disposeBag = DisposeBag()

    private let watchTypeRelay = BehaviorRelay<WatchModule.WatchType>(value: .evmAddress)
    private let watchEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let proceedRelay = PublishRelay<(WatchModule.WatchType, AccountType, String)>()

    init(service: WatchService, evmAddressViewModel: IWatchSubViewModel, publicKeyViewModel: IWatchSubViewModel) {
        self.service = service
        self.evmAddressViewModel = evmAddressViewModel
        self.publicKeyViewModel = publicKeyViewModel

        syncSubViewModel()
    }

    private var subViewModel: IWatchSubViewModel {
        switch watchTypeRelay.value {
        case .evmAddress: return evmAddressViewModel
        case .publicKey: return publicKeyViewModel
        }
    }

    private func syncSubViewModel() {
        disposeBag = DisposeBag()
        sync(watchEnabled: subViewModel.watchEnabled)
        subscribe(disposeBag, subViewModel.watchEnabledObservable) { [weak self] in self?.sync(watchEnabled: $0) }
        subscribe(disposeBag, subViewModel.nameObservable) { [weak self] in self?.sync(name: $0) }
    }

    private func sync(watchEnabled: Bool) {
        watchEnabledRelay.accept(watchEnabled)
    }

    private func sync(name: String?) {
        if let name = name, service.name == nil {
            service.set(name: name)
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

    var namePlaceholder: String {
        service.defaultAccountName
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
            proceedRelay.accept((watchTypeRelay.value, accountType, service.resolvedName))
        }
    }

}
