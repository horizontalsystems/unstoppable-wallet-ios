import RxSwift
import RxCocoa
import EvmKit
import MarketKit

class SendEip721ViewModel {
    private let service: SendEip721Service
    private let disposeBag = DisposeBag()

    private let proceedEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let proceedRelay = PublishRelay<SendEvmData>()

    init(service: SendEip721Service) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        sync(state: service.state)
    }

    private func sync(state: SendEip721Service.State) {
        if case .ready = state {
            proceedEnabledRelay.accept(true)
        } else {
            proceedEnabledRelay.accept(false)
        }
    }

}

extension SendEip721ViewModel {

    var proceedEnableDriver: Driver<Bool> {
        proceedEnabledRelay.asDriver()
    }

    var proceedSignal: Signal<SendEvmData> {
        proceedRelay.asSignal()
    }

    var nftImage: NftImage? {
        service.nftImage
    }

    var name: String {
        service.assetShortMetadata?.displayName ?? "#\(service.nftUid.tokenId)"
    }

    func didTapProceed() {
        guard case .ready(let sendData) = service.state else {
            return
        }

        proceedRelay.accept(sendData)
    }

}
