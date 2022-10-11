import Foundation
import RxSwift
import RxCocoa
import BigInt
import CurrencyKit

class SendEip1155AvailableBalanceViewModel {
    private var queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.available-balance-view-model", qos: .userInitiated)

    private let service: SendEip1155Service
    private let disposeBag = DisposeBag()

    private let viewStateRelay = BehaviorRelay<SendAvailableBalanceViewModel.ViewState>(value: .loading)

    init(service: SendEip1155Service) {
        self.service = service

        subscribe(disposeBag, service.availableBalanceObservable) { [weak self] _ in self?.sync() }

        sync()
    }

    private var hasPreviousValue: Bool {
        if case .loaded = viewStateRelay.value {
            return true
        }
        return false
    }

    private func sync() {
        queue.async { [weak self] in
            guard let weakSelf = self else {
                return
            }

            switch weakSelf.service.availableBalance {
            case .loading:
                if !weakSelf.hasPreviousValue {
                    weakSelf.viewStateRelay.accept(.loading)
                }
            case .failed: weakSelf.updateViewState(availableBalance: 0)
            case .completed(let availableBalance): weakSelf.updateViewState(availableBalance: availableBalance)
            }
        }
    }

    private func updateViewState(availableBalance: Int) {
        let value: String?

        value = ["\(availableBalance)", "NFT"].compactMap { $0 }.joined(separator: " ")

        viewStateRelay.accept(.loaded(value: value))
    }

}

extension SendEip1155AvailableBalanceViewModel: ISendAvailableBalanceViewModel {

    var viewStateDriver: Driver<SendAvailableBalanceViewModel.ViewState> {
        viewStateRelay.asDriver()
    }

}
