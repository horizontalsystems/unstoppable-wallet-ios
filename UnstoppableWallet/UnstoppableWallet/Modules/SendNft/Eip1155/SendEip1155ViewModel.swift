import Foundation
import RxSwift
import RxCocoa
import EvmKit
import MarketKit

class SendEip1155ViewModel {
    private let service: SendEip1155Service
    private let disposeBag = DisposeBag()

    private let proceedEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let amountCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let proceedRelay = PublishRelay<SendEvmData>()

    init(service: SendEip1155Service) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.amountCautionObservable) { [weak self] in self?.sync(amountCaution: $0) }

        sync(state: service.state)
    }

    private func sync(state: SendEip1155Service.State) {
        if case .ready = state {
            proceedEnabledRelay.accept(true)
        } else {
            proceedEnabledRelay.accept(false)
        }
    }

    private func sync(amountCaution: Error?) {
        var caution: Caution? = nil

        if let error = amountCaution {
            caution = Caution(text: error.smartDescription, type: .error)
        }

        amountCautionRelay.accept(caution)
    }

}

extension SendEip1155ViewModel {

    var showKeyboard: Bool {
        (service.balance ?? 0) != 1 // If balance == 1 don't show keyboard
    }

    var proceedEnableDriver: Driver<Bool> {
        proceedEnabledRelay.asDriver()
    }

    var amountCautionDriver: Driver<Caution?> {
        amountCautionRelay.asDriver()
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

extension SendEip1155Service.AmountError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .insufficientBalance: return "send.amount_error.balance".localized
        }
    }

}
