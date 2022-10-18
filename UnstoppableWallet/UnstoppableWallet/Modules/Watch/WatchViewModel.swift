import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol IWatchSubViewModel: AnyObject {
    var watchEnabled: Bool { get }
    var watchEnabledObservable: Observable<Bool> { get }
    func resolve() -> (AccountType, String?)?
}

class WatchViewModel {
    private let service: WatchService
    private let evmAddressViewModel: IWatchSubViewModel
    private let publicKeyViewModel: IWatchSubViewModel
    private var disposeBag = DisposeBag()

    private let watchTypeRelay = BehaviorRelay<WatchType>(value: .evmAddress)
    private let watchEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let finishRelay = PublishRelay<Void>()

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
    }

    private func sync(watchEnabled: Bool) {
        watchEnabledRelay.accept(watchEnabled)
    }

}

extension WatchViewModel {

    var watchTypeDriver: Driver<WatchType> {
        watchTypeRelay.asDriver()
    }

    var watchEnabledDriver: Driver<Bool> {
        watchEnabledRelay.asDriver()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func onSelect(watchType: WatchType) {
        guard watchTypeRelay.value != watchType else {
            return
        }

        watchTypeRelay.accept(watchType)
        syncSubViewModel()
    }

    func onTapWatch() {
        if let (accountType, name) = subViewModel.resolve() {
            service.watch(accountType: accountType, name: name)
            finishRelay.accept(())
        }
    }

}

extension WatchViewModel {

    enum WatchType: CaseIterable {
        case evmAddress
        case publicKey

        var title: String {
            switch self {
            case .evmAddress: return "watch_address.evm_address".localized
            case .publicKey: return "watch_address.public_key".localized
            }
        }
    }

}
